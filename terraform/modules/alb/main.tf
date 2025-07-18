resource "aws_lb" "main" {
  name               = "shortlink-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
  tags = {
    Name = "${var.env}-alb"
  }
}

# Target group for CapRover's HTTP port (80)
resource "aws_lb_target_group" "caprover_http" {
  name     = "caprover-http-tg"
  port     = 80
  protocol = "HTTP"
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

# Target group for CapRover's HTTPS port (443)
resource "aws_lb_target_group" "caprover_https" {
  name     = "caprover-https-tg"
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

# Target group for CapRover's dashboard port (3000)
resource "aws_lb_target_group" "caprover_dashboard" {
  name     = "caprover-dashboard-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/app/captain/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Attach CapRover instance to the target groups
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

# ALB Listener for HTTP (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener for HTTPS (forward to CapRover's HTTPS target group)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.caprover_https.arn
  }
}

# ALB Listener for CapRover Dashboard (port 3000)
resource "aws_lb_listener" "dashboard" {
  load_balancer_arn = aws_lb.main.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.caprover_dashboard.arn
  }
}

resource "aws_lb_target_group" "gitlab_http" {
  name     = "gitlab-http-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/users/sign_in"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200,302"
  }
}

resource "aws_lb_target_group_attachment" "gitlab_http" {
  target_group_arn = aws_lb_target_group.gitlab_http.arn
  target_id        = var.gitlab_instance_id
  port             = 80
}

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