data "aws_iam_policy_document" "op_conn_ecs_tasks" {
  statement {
    sid = "AssumeOpConnEcsTasksRole"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "op_conn_ecs_tasks" {
  description        = "1Password Connect - Role for ECS Task Execution"
  name               = "${var.prefix}-ecs-tasks"
  assume_role_policy = data.aws_iam_policy_document.op_conn_ecs_tasks.json
}
data "aws_iam_policy_document" "op_conn_ecs_tasks_exec" {
  statement {
    sid    = "AllowEcsTaskExecution"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "op_conn_ecs_tasks_exec" {
  name        = "${var.prefix}-ecs-tasks-exec"
  description = "Allow ECS Tasks to function"
  policy      = data.aws_iam_policy_document.op_conn_ecs_tasks_exec.json
}
resource "aws_iam_role_policy_attachment" "op_conn_ecs_tasks_exec" {
  role       = aws_iam_role.op_conn_ecs_tasks.name
  policy_arn = aws_iam_policy.op_conn_ecs_tasks_exec.arn
}
