variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "security_groups" {
  type = list(string)
}
variable "env" {
  default = "prod"
}
