output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "caprover_http_tg_arn" {
  value = aws_lb_target_group.caprover_http.arn
}

output "caprover_https_tg_arn" {
  value = aws_lb_target_group.caprover_https.arn
}

output "caprover_dashboard_tg_arn" {
  value = aws_lb_target_group.caprover_dashboard.arn
}