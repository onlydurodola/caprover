variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}

variable "caprover_sg_id" {
  description = "Security group ID for CapRover instance"
  type        = string
}

variable "gitlab_sg_id" {
  description = "Security group ID for GitLab instance"
  type        = string
}

variable "env" {
  default = "prod"
}
