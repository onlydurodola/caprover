data "aws_availability_zones" "available" {
  state = "available"
}

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

resource "aws_ebs_volume" "caprover_data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 50
  type              = "gp3"
  tags = {
    Name = "${var.env}-caprover-data"
  }
}

resource "aws_ebs_volume" "gitlab_data" {
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = 100
  type              = "gp3"
  tags = {
    Name = "${var.env}-gitlab-data"
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

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3 python3-distutils
    sudo snap install amazon-ssm-agent --classic
    sudo snap start amazon-ssm-agent
    echo "SSM Agent status:"
    sudo snap services amazon-ssm-agent
    
    # Wait for EBS volume to be available
    while [ ! -e /dev/sdh ]; do sleep 2; done
    
    # Format if not formatted
    if ! sudo blkid /dev/sdh; then
      sudo mkfs -t ext4 /dev/sdh
    fi
    
    # Mount persistent volume
    sudo mkdir -p /captain
    sudo mount /dev/sdh /captain
    echo "/dev/sdh /captain ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
    
    # Ensure permissions
    sudo chown -R ubuntu:ubuntu /captain
  EOF

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

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3 python3-distutils
    sudo snap install amazon-ssm-agent --classic
    sudo snap start amazon-ssm-agent
    echo "SSM Agent status:"
    sudo snap services amazon-ssm-agent
    
    # Wait for EBS volume to be available
    while [ ! -e /dev/sdi ]; do sleep 2; done
    
    # Format if not formatted
    if ! sudo blkid /dev/sdi; then
      sudo mkfs -t ext4 /dev/sdi
    fi
    
    # Mount persistent volume
    sudo mkdir -p /var/opt/gitlab
    sudo mount /dev/sdi /var/opt/gitlab
    echo "/dev/sdi /var/opt/gitlab ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
    
    # Ensure permissions
    sudo chown -R git:root /var/opt/gitlab
  EOF

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "${var.env}-gitlab"
  }
}

resource "aws_volume_attachment" "caprover_att" {
  device_name = "/dev/sdh" # Changed to unused device
  volume_id   = aws_ebs_volume.caprover_data.id
  instance_id = aws_instance.caprover.id
}

resource "aws_volume_attachment" "gitlab_att" {
  device_name = "/dev/sdi" # Changed to unused device
  volume_id   = aws_ebs_volume.gitlab_data.id
  instance_id = aws_instance.gitlab.id
}