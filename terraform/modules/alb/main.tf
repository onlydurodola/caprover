resource "random_id" "tg_suffix" {
  byte_length = 4
}

resource "aws_lb" "main" {
  name               = "shortlink-alb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids


  tags = {
    Name = "${var.env}-alb"
  }
}

# Target Groups
resource "aws_lb_target_group" "caprover_http" {
  name     = "caprover-http-tg-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "caprover_https" {
  name     = "caprover-https-tg-${var.env}"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "caprover_dashboard" {
  name        = "caprover-dash-tg-${var.env}-${random_id.tg_suffix.hex}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "gitlab_http" {
  name        = "gitlab-${var.env}-tg-${random_id.tg_suffix.hex}"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/users/sign_in"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399" # Updated matcher
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.env}-gitlab-tcp-tg"
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "caprover_http" {
  target_group_arn = aws_lb_target_group.caprover_http.arn
  target_id        = var.caprover_instance_id
  port             = 80

}

resource "aws_lb_target_group_attachment" "caprover_https" {
  target_group_arn = aws_lb_target_group.caprover_https.arn
  target_id        = var.caprover_instance_id
  port             = 443
}

resource "aws_lb_target_group_attachment" "caprover_dashboard" {
  target_group_arn = aws_lb_target_group.caprover_dashboard.arn
  target_id        = var.caprover_instance_id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "gitlab_http" {
  target_group_arn = aws_lb_target_group.gitlab_http.arn
  target_id        = var.gitlab_instance_id
  port             = 8081
}

# Listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
      message_body = "Invalid request"
    }

  }
}

# Listener Rules
resource "aws_lb_listener_rule" "gitlab_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab_http.arn
  }

  condition {
    host_header {
      values = ["gitlab.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "gitlab_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab_http.arn
  }

  condition {
    host_header {
      values = ["gitlab.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "caprover_dashboard" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.caprover_https.arn
  }

  condition {
    host_header {
      values = ["captain.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "caprover_dashboard_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.caprover_dashboard.arn
  }

  condition {
    host_header {
      values = ["captain.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "main_domain" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.caprover_dashboard.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }
}

