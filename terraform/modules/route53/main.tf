resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gitlab" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "gitlab.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.gitlab_ip]
}
