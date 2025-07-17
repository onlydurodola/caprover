output "caprover_instance_ip" {
  value = aws_instance.caprover.public_ip
}

output "gitlab_instance_ip" {
  value = aws_instance.gitlab.public_ip
}
output "caprover_instance_id" {
  value = aws_instance.caprover.id
}

output "gitlab_instance_id" {
  value = aws_instance.gitlab.id
}
