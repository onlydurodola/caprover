output "caprover_sg_id" {
  value = aws_security_group.caprover.id
}

output "gitlab_sg_id" {
  value = aws_security_group.gitlab.id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}
output "internal_sg_id" {
  value = aws_security_group.internal.id
}
