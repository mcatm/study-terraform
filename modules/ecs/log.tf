resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name              = "ecs-log-group-${var.build_env}"
  retention_in_days = 30
  tags = {
    Name = "ih-log-${var.build_env}"
  }
}

resource "aws_cloudwatch_log_stream" "ecs-log-stream" {
  name           = "ecs-log-group-${var.build_env}"
  log_group_name = aws_cloudwatch_log_group.ecs-log-group.name
}