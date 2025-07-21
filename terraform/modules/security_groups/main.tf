resource "aws_security_group" "caprover" {
  name        = "${var.env}-caprover-sg"
  description = "CapRover Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env}-caprover-sg"
  }
}

resource "aws_security_group" "gitlab" {
  name        = "${var.env}-gitlab-sg"
  description = "GitLab Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env}-gitlab-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.env}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env}-alb-sg"
  }
}

# CapRover SG Rules
resource "aws_security_group_rule" "caprover_ingress_ssh" {
  security_group_id = aws_security_group.caprover.id
  type              = "ingress"
  description       = "SSH from allowed IPs"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ips
}

resource "aws_security_group_rule" "caprover_ingress_http" {
  security_group_id        = aws_security_group.caprover.id
  type                     = "ingress"
  description              = "HTTP from ALB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "caprover_ingress_https" {
  security_group_id        = aws_security_group.caprover.id
  type                     = "ingress"
  description              = "HTTPS from ALB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "caprover_ingress_dashboard" {
  security_group_id        = aws_security_group.caprover.id
  type                     = "ingress"
  description              = "Dashboard from ALB"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "caprover_ingress_clustering_tcp_996" {
  security_group_id = aws_security_group.caprover.id
  type              = "ingress"
  description       = "CapRover clustering TCP"
  from_port         = 996
  to_port           = 996
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "caprover_ingress_clustering_tcp_7946" {
  security_group_id = aws_security_group.caprover.id
  type              = "ingress"
  description       = "CapRover clustering TCP/UDP"
  from_port         = 7946
  to_port           = 7946
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "caprover_ingress_clustering_udp_7946" {
  security_group_id = aws_security_group.caprover.id
  type              = "ingress"
  description       = "CapRover clustering UDP"
  from_port         = 7946
  to_port           = 7946
  protocol          = "udp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "caprover_ingress_overlay_udp_4789" {
  security_group_id = aws_security_group.caprover.id
  type              = "ingress"
  description       = "CapRover overlay UDP"
  from_port         = 4789
  to_port           = 4789
  protocol          = "udp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "caprover_ingress_swarm_tcp_2377" {
  security_group_id = aws_security_group.caprover.id
  type              = "ingress"
  description       = "Docker swarm TCP"
  from_port         = 2377
  to_port           = 2377
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "caprover_egress_all" {
  security_group_id = aws_security_group.caprover.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# GitLab SG Rules
resource "aws_security_group_rule" "gitlab_ingress_ssh" {
  security_group_id = aws_security_group.gitlab.id
  type              = "ingress"
  description       = "SSH from allowed IPs"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ips
}

resource "aws_security_group_rule" "gitlab_ingress_http_alb" {
  security_group_id        = aws_security_group.gitlab.id
  type                     = "ingress"
  description              = "GitLab HTTP from ALB"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "gitlab_ingress_http_caprover" {
  security_group_id        = aws_security_group.gitlab.id
  type                     = "ingress"
  description              = "Internal GitLab access from CapRover"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.caprover.id
}

resource "aws_security_group_rule" "gitlab_egress_all" {
  security_group_id = aws_security_group.gitlab.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ALB SG Rules
resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  description       = "HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  description       = "HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress_gitlab" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  description              = "Outbound to GitLab"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "alb_egress_caprover_http" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  description              = "Outbound to CapRover HTTP"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.caprover.id
}

resource "aws_security_group_rule" "alb_egress_caprover_https" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  description              = "Outbound to CapRover HTTPS"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.caprover.id
}

resource "aws_security_group_rule" "alb_egress_caprover_dashboard" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  description              = "Outbound to CapRover Dashboard"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.caprover.id
}