variable "vpc_id" {}
variable "public_subnet_ids" {}
variable "security_group_id" {}
variable "certificate_arn" {}
variable "caprover_instance_id" {}
variable "gitlab_instance_id" {}
variable "domain_name" {}
variable "env" {
  default = "prod"
}
