resource "aws_security_group" "vpn" {
  name        = "${var.env}-vpn-sg"
  description = "Security group for Client VPN"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-vpn-sg"
  }
}

resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "${var.env}-client-vpn"
  server_certificate_arn = var.server_cert_arn
  client_cidr_block      = var.vpn_cidr
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.vpn.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.root_cert_arn
  }

  connection_log_options {
    enabled = false
  }

  tags = {
    Name = "${var.env}-client-vpn"
  }
}

resource "aws_ec2_client_vpn_network_association" "main" {
  count                  = length(var.public_subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = var.public_subnet_ids[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}
