locals {
  # Create IP set only if allowed_ips doesn't contain 0.0.0.0/0
  create_ip_set = length(var.allowed_ips) > 0 && !contains(var.allowed_ips, "0.0.0.0/0")
}

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.env}-waf-acl"
  description = "WAF for CapRover infrastructure"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Conditional whitelist rule
  dynamic "rule" {
    for_each = local.create_ip_set ? [1] : []
    content {
      name     = "IPWhitelist"
      priority = 2
      action {
        block {}
      }
      statement {
        not_statement {
          statement {
            ip_set_reference_statement {
              arn = aws_wafv2_ip_set.whitelist[0].arn
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "IPWhitelist"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "RateLimit"
    priority = local.create_ip_set ? 3 : 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-waf-metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_ip_set" "whitelist" {
  count               = local.create_ip_set ? 1 : 0
  name                = "${var.env}-whitelist"
  scope               = "REGIONAL"
  ip_address_version  = "IPV4"
  addresses           = var.allowed_ips
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}