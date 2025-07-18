variable "alb_arn" {
  description = "ARN of the ALB to protect"
  type        = string
}

variable "allowed_ips" {
  description = "List of whitelisted IPs in CIDR notation"
  type        = list(string)
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "prod"
}