resource "aws_security_group" "op_conn_alb" {
  description = "Access to the public facing load balancer"
  vpc_id      = var.op_networking.vpc_id
  name        = "${var.prefix}-alb-sg"
}
resource "aws_security_group_rule" "op_conn_alb_ingress" {
  security_group_id = aws_security_group.op_conn_alb.id
  cidr_blocks       = var.op_alb.inbound_cidr
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
}
resource "aws_security_group_rule" "op_conn_alb_egress" {
  security_group_id        = aws_security_group.op_conn_alb.id
  source_security_group_id = aws_security_group.op_conn_fargate.id
  type                     = "egress"
  protocol                 = "TCP"
  from_port                = local.op_conn_api_host_port
  to_port                  = local.op_conn_api_host_port
}

resource "aws_security_group" "op_conn_fargate" {
  description = "Access to the fargate containers"
  name        = "${var.prefix}-fargate-sg"
  vpc_id      = var.op_networking.vpc_id
}
resource "aws_security_group_rule" "op_conn_fargate_ingress_from_lb" {
  description              = "ingress from the public ALB"
  security_group_id        = aws_security_group.op_conn_fargate.id
  source_security_group_id = aws_security_group.op_conn_alb.id
  protocol                 = "TCP"
  # TODO: START HERE if issues with connectivity
  to_port   = local.op_conn_api_host_port
  from_port = local.op_conn_api_host_port
  type      = "ingress"
}
resource "aws_security_group_rule" "op_conn_fargate_ingress_from_self" {
  description       = "Ingress from other containers in the same security group"
  self              = true
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.op_conn_fargate.id
  type              = "ingress"
}
resource "aws_security_group_rule" "op_conn_egress" {
  from_port         = 0
  protocol          = "TCP"
  security_group_id = aws_security_group.op_conn_fargate.id
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}
