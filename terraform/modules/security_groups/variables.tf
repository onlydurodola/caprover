variable "vpc_id" {}
variable "allowed_ips" {}
variable "env" {
  default = "prod"
}
variable "vpc_cidr" {
  type = string
}
