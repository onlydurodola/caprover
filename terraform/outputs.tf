output "caprover_instance_ip" {
  value = module.ec2.caprover_instance_ip
}

output "gitlab_instance_ip" {
  value = module.ec2.gitlab_instance_ip
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
