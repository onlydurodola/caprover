data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "caprover" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.caprover_sg_id]
  key_name                    = "shortlink"
  iam_instance_profile        = var.iam_instance_profile_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3 python3-distutils
    sudo snap install amazon-ssm-agent --classic
    sudo snap start amazon-ssm-agent
    echo "SSM Agent status:"
    sudo snap services amazon-ssm-agent
    EOF

  lifecycle {
    ignore_changes        = [associate_public_ip_address]
    create_before_destroy = true
  }
  tags = {
    Name = "${var.env}-caprover"
  }
}

resource "aws_instance" "gitlab" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.xlarge"
  subnet_id                   = var.public_subnet_ids[1]
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.gitlab_sg_id]
  key_name                    = "shortlink"
  iam_instance_profile        = var.iam_instance_profile_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3 python3-distutils
    sudo snap install amazon-ssm-agent --classic
    sudo snap start amazon-ssm-agent
    echo "SSM Agent status:"
    sudo snap services amazon-ssm-agent
    EOF

  lifecycle {
    ignore_changes        = [associate_public_ip_address]
    create_before_destroy = true
  }
  root_block_device {
    volume_size = 20
  }
  tags = {
    Name = "${var.env}-gitlab"
  }
}
#