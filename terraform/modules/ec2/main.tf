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
    set -e
    # Update and install prerequisites
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-distutils
    # Check if SSM Agent is already installed
    if ! dpkg -l | grep -q amazon-ssm-agent; then
      # Download and install SSM Agent
      wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
      sudo dpkg -i amazon-ssm-agent.deb
      rm amazon-ssm-agent.deb
    fi
    # Ensure SSM Agent service is enabled and started
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
    # Wait for SSM Agent to be active
    for i in {1..5}; do
      if sudo systemctl is-active amazon-ssm-agent >/dev/null; then
        exit 0
      fi
      sleep 5
    done
    exit 1
    EOF
  lifecycle {
    ignore_changes = [associate_public_ip_address]
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
    set -e
    # Update and install prerequisites
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-distutils
    # Check if SSM Agent is already installed
    if ! dpkg -l | grep -q amazon-ssm-agent; then
      # Download and install SSM Agent
      wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
      sudo dpkg -i amazon-ssm-agent.deb
      rm amazon-ssm-agent.deb
    fi
    # Ensure SSM Agent service is enabled and started
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
    # Wait for SSM Agent to be active
    for i in {1..5}; do
      if sudo systemctl is-active amazon-ssm-agent >/dev/null; then
        exit 0
      fi
      sleep 5
    done
    exit 1
    EOF
  lifecycle {
    ignore_changes = [associate_public_ip_address]
    create_before_destroy = true
  }
  root_block_device {
    volume_size = 20
  }
  tags = {
    Name = "${var.env}-gitlab"
  }
}