variable "vpc_id" {
  description = "VPC ID for VPN association"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for VPN association"
  type        = list(string)
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpn_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
  default     = "10.100.0.0/22"
}

variable "root_cert_arn" {
  description = "ARN of the root certificate"
  type        = string
}

variable "server_cert_arn" {
  description = "ARN of the server certificate"
  type        = string
}
