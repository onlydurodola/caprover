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

resource "aws_instance" "caprover" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.caprover_sg_id]
  key_name                    = "shortlink"
  iam_instance_profile        = var.iam_instance_profile_name
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 50
    volume_type = "gp3"
    tags = {
      Name = "${var.env}-caprover-data"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3 python3-distutils
    sudo snap install amazon-ssm-agent --classic
    sudo snap start amazon-ssm-agent
    echo "SSM Agent status:"
    sudo snap services amazon-ssm-agent
    
    # Wait for EBS volume to be available
    while [ ! -e /dev/nvme1n1 ]; do sleep 2; done
    
    # Format and mount CapRover data volume
    if ! blkid /dev/nvme1n1; then
      sudo mkfs -t ext4 /dev/nvme1n1
    fi
    sudo mkdir -p /captain
    sudo mount /dev/nvme1n1 /captain
    echo "/dev/nvme1n1 /captain ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
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
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 100 # GitLab requires more space
    volume_type = "gp3"
    tags = {
      Name = "${var.env}-gitlab-data"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3 python3-distutils
    sudo snap install amazon-ssm-agent --classic
    sudo snap start amazon-ssm-agent
    echo "SSM Agent status:"
    sudo snap services amazon-ssm-agent
    
    # Wait for EBS volume to be available
    while [ ! -e /dev/nvme2n1 ]; do sleep 2; done
    
    # Format and mount GitLab data volume
    if ! blkid /dev/nvme2n1; then
      sudo mkfs -t ext4 /dev/nvme2n1
    fi
    sudo mkdir -p /var/opt/gitlab
    sudo mount /dev/nvme2n1 /var/opt/gitlab
    echo "/dev/nvme2n1 /var/opt/gitlab ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
  EOF

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "${var.env}-gitlab"
  }
}

resource "aws_ebs_volume" "caprover_data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 50
  type              = "gp3"
  tags = {
    Name = "${var.env}-caprover-data"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ebs_volume" "gitlab_data" {
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = 100
  type              = "gp3"
  tags = {
    Name = "${var.env}-gitlab-data"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "caprover_ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.caprover_data.id
  instance_id = aws_instance.caprover.id

  lifecycle {
    ignore_changes = [instance_id]
  }
}

resource "aws_volume_attachment" "gitlab_ebs_att" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.gitlab_data.id
  instance_id = aws_instance.gitlab.id

  lifecycle {
    ignore_changes = [instance_id]
  }
}