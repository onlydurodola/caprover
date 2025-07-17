data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "caprover" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id = var.public_subnet_ids[0]
  vpc_security_group_ids = [
    var.caprover_sg_id,
    var.internal_sg_id
  ]
  key_name = "shortlink"
  user_data = file("${path.module}/userdata.sh")
  tags = { 
    Name = "${var.env}-caprover"
  }
}

resource "aws_instance" "gitlab" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id = var.public_subnet_ids[1]
  vpc_security_group_ids = [
    var.caprover_sg_id,
    var.internal_sg_id
  ]
  key_name = "shortlink"
  user_data = file("${path.module}/userdata.sh")
  tags = { 
    Name = "${var.env}-gitlab"
  }
}
