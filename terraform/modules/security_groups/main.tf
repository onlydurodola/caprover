resource "aws_security_group" "internal" {
  name = "${var.env}-internal-sg"
  description = "Allow communication between CapRover and GitLab"
  vpc_id = var.vpc_id

  ingress {
    description = "All internal traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.vpc_cidr] # Allow all VPC traffic
  }

  tags = {
    Name = "${var.env}-internal-sg"
  }
}

resource "aws_security_group" "caprover" {
  name = "${var.env}-caprover-sg"
  description = "CapRover Security Group"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH from allowed IPs"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "HTTP from ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "HTTPS from ALB"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Internal VPC traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-caprover-sg"
  }
}

resource "aws_security_group" "gitlab" {
  name = "${var.env}-gitlab-sg"
  description = "GitLab Security Group"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH from allowed IPs"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "HTTP from anywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Internal VPC traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-gitlab-sg"
  }
}

resource "aws_security_group" "alb" {
  name = "${var.env}-alb-sg"
  description = "ALB Security Group"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTPS from anywhere"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to CapRover"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.caprover.id]
  }

  tags = {
    Name = "${var.env}-alb-sg"
  }
}
