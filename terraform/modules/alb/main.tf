resource "aws_lb" "main" {
  name = "shortlink-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [var.security_group_id]
  subnets = var.public_subnet_ids
  tags = {
    Name = "${var.env}-alb"
  }
}

resource "aws_lb_target_group" "caprover" {
  name = "caprover-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  
  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200-399"
  }
}

resource "aws_lb_target_group_attachment" "caprover" {
  target_group_arn = aws_lb_target_group.caprover.arn
  target_id = var.caprover_instance_id 
  port = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = var.certificate_arn
  
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.caprover.arn
  }
}
