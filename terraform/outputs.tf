output "caprover_instance_ip" {
  value = module.ec2.caprover_instance_ip
}

output "gitlab_instance_ip" {
  value = module.ec2.gitlab_instance_ip
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
output "caprover_sg_id" {
  value = module.security_groups.caprover_sg_id
}

output "gitlab_sg_id" {
  value = module.security_groups.gitlab_sg_id
}

output "waf_web_acl_arn" {
  value = var.waf_enabled ? module.waf[0].web_acl_arn : null
}

output "vpc_cidr" {
  value = var.vpc_cidr
}
