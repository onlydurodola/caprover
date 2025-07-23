provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "ssm_role" {
  name = "SSMInstanceRole-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile-${var.env}"
  role = aws_iam_role.ssm_role.name
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  aws_region           = var.aws_region
  env                  = var.env
}

module "security_groups" {
  source        = "./modules/security_groups"
  vpc_id        = module.vpc.vpc_id
  vpc_cidr      = var.vpc_cidr
  env           = var.env
  my_current_ip = var.my_current_ip
}

module "ecr" {
  source = "./modules/ecr"

}

module "ec2" {
  source                    = "./modules/ec2"
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  depends_on                = [module.vpc, module.security_groups]
  caprover_sg_id            = module.security_groups.caprover_sg_id
  gitlab_sg_id              = module.security_groups.gitlab_sg_id
  env                       = var.env
  iam_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "alb" {
  source               = "./modules/alb"
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  security_group_id    = module.security_groups.alb_sg_id
  caprover_instance_id = module.ec2.caprover_instance_id
  gitlab_instance_id   = module.ec2.gitlab_instance_id
  certificate_arn      = var.certificate_arn
  domain_name          = var.domain_name
  env                  = var.env
}

module "route53" {
  source       = "./modules/route53"
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  depends_on   = [module.alb]
}

module "waf" {
  count       = var.waf_enabled ? 1 : 0
  source      = "./modules/waf"
  alb_arn     = module.alb.alb_arn
  allowed_ips = var.allowed_ips
  env         = var.env

}

module "vpn" {
  count             = var.vpn_enabled ? 1 : 0
  source            = "./modules/vpn"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  env               = var.env
  root_cert_arn     = var.root_cert_arn
  server_cert_arn   = var.server_cert_arn
  vpn_cidr          = var.vpn_cidr
}


resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "ansible_ssm" {
  # Bucket names must be globally unique. A random suffix helps.
  bucket = "caprover-ansible-ssm-${random_id.bucket_suffix.hex}"

  # A best practice to prevent accidental deletion of a production bucket
  # Set to true for ephemeral environments if needed.
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}