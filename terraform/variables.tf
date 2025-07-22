variable "aws_region" {
  default = "eu-north-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "allowed_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "domain_name" {
  default = "oluwatobiloba.tech"
}

variable "certificate_arn" {
}
variable "env" {
  default = "prod"
}

variable "waf_enabled" {
  description = "Enable or disable WAF"
  type        = bool
  default     = true
}

variable "my_current_ip" {
  description = "Current public IP for temporary access"
  type        = string
  default     = ""
}

variable "vpn_enabled" {
  description = "Enable AWS Client VPN"
  type        = bool
  default     = true
}

variable "root_cert_arn" {
  description = "ARN of the root certificate for VPN"
  type        = string
  default     = ""
}

variable "server_cert_arn" {
  description = "ARN of the server certificate for VPN"
  type        = string
  default     = ""
}

variable "vpn_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
  default     = "10.100.0.0/22"
}