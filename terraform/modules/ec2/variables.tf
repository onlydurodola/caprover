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

variable "iam_instance_profile_name" {
  description = "IAM instance profile name for SSM"
  type        = string
}

output "caprover_instance_ip" {
  value       = aws_instance.caprover.public_ip
  description = "The public IP of the CapRover instance"
}

output "gitlab_instance_ip" {
  value       = aws_instance.gitlab.public_ip
  description = "The public IP of the GitLab instance"
}
