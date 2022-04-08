resource "aws_ecs_cluster" "op_connect" {
  name = "${var.prefix}-ecs"
}

locals {
  op_conn_source_volume = "${var.prefix}-data-volume"
  op_conn_api_container = "${var.prefix}-connect-api"
  op_conn_api_host_port = 8080
  op_conn_mount_points = [
    {
      containerPath = "/home/opuser/.op/data"
      sourceVolume  = local.op_conn_source_volume
    }
  ]
  op_conn_base_env = [
    { name = "OP_SESSION", value = var.op_creds_base64 },
  ]
  op_conn_base_logging = {
    awslogs-group  = aws_cloudwatch_log_group.op_conn_logs.name
    awslogs-region = data.aws_region.current.name
  }
  op_connect_api_def = {
    name         = local.op_conn_api_container
    image        = "1password/connect-api:latest"
    essential    = true
    portMappings = [{ containerPort = 8080, hostPort = local.op_conn_api_host_port }]
    mountPoints  = local.op_conn_mount_points
    environment  = local.op_conn_base_env
    logConfiguration = {
      logDriver = "awslogs"
      options   = merge(local.op_conn_base_logging, { awslogs-stream-prefix = "${var.prefix}-connect-api" })
    }
  }
  op_connect_sync_def = {
    name        = "${var.prefix}-connect-sync"
    image       = "1password/connect-sync:latest"
    essential   = true
    mountPoints = local.op_conn_mount_points
    environment = concat(local.op_conn_base_env, [
      { name = "OP_HTTP_PORT", value = "8081" },
    ])
    logConfiguration = {
      logDriver = "awslogs"
      options   = merge(local.op_conn_base_logging, { awslogs-stream-prefix = "${var.prefix}-connect-sync" })
    }
  }
  op_conn_container_defs = [
    local.op_connect_api_def,
    local.op_connect_sync_def
  ]
}

resource "aws_ecs_task_definition" "op_connect" {
  family                   = "${var.prefix}-task-def"
  container_definitions    = jsonencode(local.op_conn_container_defs)
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.op_conn_ecs_tasks.arn
  volume {
    name = local.op_conn_source_volume
  }

  depends_on = [
    aws_iam_policy.op_conn_ecs_tasks_exec,
    aws_cloudwatch_log_group.op_conn_logs
  ]
}

resource "aws_ecs_service" "op_connect" {
  name            = "${var.prefix}-ecs-srv"
  cluster         = aws_ecs_cluster.op_connect.id
  task_definition = aws_ecs_task_definition.op_connect.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.op_conn_fargate.id]
    subnets          = var.op_networking.subnets
  }

  load_balancer {
    container_name   = local.op_conn_api_container
    container_port   = local.op_conn_api_host_port
    target_group_arn = aws_alb_target_group.op_conn_alb_tg.arn
  }

  depends_on = [
    aws_ecs_cluster.op_connect,
    aws_ecs_task_definition.op_connect,
    aws_alb_target_group.op_conn_alb_tg,
    aws_security_group.op_conn_fargate,
    aws_security_group_rule.op_conn_fargate_ingress_from_lb,
    aws_security_group_rule.op_conn_fargate_ingress_from_self,
  ]
}
