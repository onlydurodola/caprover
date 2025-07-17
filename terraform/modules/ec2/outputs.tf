output "caprover_instance_ip" {
  value = aws_instance.caprover.public_ip
}

output "gitlab_instance_ip" {
  value = aws_instance.gitlab.public_ip
}
output "internal_sg_id" {
  value = aws_security_group.internal.id
}
