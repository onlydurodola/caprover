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
  default = ["105.113.67.32/32"]
}

variable "domain_name" {
  default = "oluwatobiloba.tech"
}

variable "certificate_arn" {
}
