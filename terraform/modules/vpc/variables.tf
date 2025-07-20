variable "vpc_cidr" {}
variable "public_subnet_cidrs" {}
variable "private_subnet_cidrs" {}
variable "env" {
  default = "prod"
}
variable "aws_region" {
  description = "AWS region for the VPC"
  type        = string
}

