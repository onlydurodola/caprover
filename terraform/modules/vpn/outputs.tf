output "vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.main.id
}

output "vpn_cidr" {
  value = var.vpn_cidr
}
