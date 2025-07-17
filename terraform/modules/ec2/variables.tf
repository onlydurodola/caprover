variable "vpc_id" {}
variable "public_subnet_ids" {}
variable "caprover_sg_id" {}
variable "gitlab_sg_id" {} 
variable "env" {
  default = "prod"
}
