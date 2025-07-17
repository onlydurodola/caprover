variable "vpc_id" {}
variable "public_subnet_ids" {}
Variable "security_groups"
  type = list(string)
variable "env" {
  default = "prod"
}
