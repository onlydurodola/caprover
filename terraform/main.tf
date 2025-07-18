provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  env                  = var.env
}

module "security_groups" {
  source      = "./modules/security_groups"
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = var.vpc_cidr
  allowed_ips = var.allowed_ips
  env         = var.env
}

module "ecr" {
  source = "./modules/ecr"

}

module "ec2" {
  source            = "./modules/ec2"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_groups = [
    module.security_groups.caprover_sg_id,
    module.security_groups.gitlab_sg_id,
    module.security_groups.internal_sg_id
  ]
  env = var.env
}

module "alb" {
  source               = "./modules/alb"
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  security_group_id    = module.security_groups.alb_sg_id
  caprover_instance_id = module.ec2.caprover_instance_id
  certificate_arn      = var.certificate_arn
  env                  = var.env
}

module "route53" {
  source       = "./modules/route53"
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  gitlab_ip    = module.ec2.gitlab_instance_ip
}
