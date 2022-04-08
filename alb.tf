resource "aws_alb" "op_conn_alb" {
  name               = "${var.prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 30
  subnets            = var.op_networking.subnets
  security_groups    = [aws_security_group.op_conn_alb.id]
  depends_on = [
    aws_security_group.op_conn_alb
  ]
}

resource "aws_alb_target_group" "op_conn_alb_tg" {
  health_check {
    enabled             = true
    interval            = 30
    path                = "/heartbeat"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 7
  }
  deregistration_delay = "30"
  port                 = local.op_conn_api_host_port
  target_type          = "ip"
  protocol             = "HTTP"
  vpc_id               = var.op_networking.vpc_id
  name                 = "${var.prefix}-connect-tg"
  depends_on           = [aws_alb.op_conn_alb]
}

resource "aws_alb_listener" "op_conn_alb_listen_https" {
  load_balancer_arn = aws_alb.op_conn_alb.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.op_conn_alb_tg.arn
  }
  port            = 443
  protocol        = "HTTPS"
  certificate_arn = var.op_alb.acm_cert_arn
  depends_on      = [aws_alb.op_conn_alb]
}

resource "aws_route53_record" "op_con_alias_record" {
  name    = var.op_alb.domain
  zone_id = var.op_alb.hosted_zone
  type    = "A"
  alias {
    evaluate_target_health = true
    name                   = aws_alb.op_conn_alb.dns_name
    zone_id                = aws_alb.op_conn_alb.zone_id
  }
}
