resource "aws_cloudwatch_log_group" "op_conn_logs" {
  name              = "${var.prefix}-container-logs"
  retention_in_days = 180
}
