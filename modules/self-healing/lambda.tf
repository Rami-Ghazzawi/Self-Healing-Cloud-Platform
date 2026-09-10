data "archive_file" "self_healing_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/self_healing.py"
  output_path = "${path.module}/lambda/self_healing.zip"
}


resource "aws_cloudwatch_log_group" "self_healing" {
  name              = "/aws/lambda/${var.environment}-self-healing-controller"

  retention_in_days = 14
}


resource "aws_lambda_function" "self_healing" {
  function_name = "${var.environment}-self-healing-controller"

  role = aws_iam_role.self_healing.arn

  handler = "self_healing.lambda_handler"

  runtime = "python3.12"

  timeout = 30

  filename = data.archive_file.self_healing_lambda.output_path

  source_code_hash = (
    data.archive_file.self_healing_lambda.output_base64sha256
  )

  environment {
    variables = {
      ECS_CLUSTER      = var.ecs_cluster
      ECS_SERVICE      = var.ecs_service
      TARGET_GROUP_ARN = var.target_group_arn

      MIN_TASKS = tostring(
        var.min_tasks
      )

      MAX_TASKS = tostring(
        var.max_tasks
      )

      CPU_SCALE_INCREMENT = tostring(
        var.cpu_scale_increment
      )

      MAX_RETRIES = tostring(
        var.max_retries
      )

      COOLDOWN_SECONDS = tostring(
        var.cooldown_seconds
      )

      SCHEDULER_ROLE_ARN = (
        aws_iam_role.scheduler_execution.arn
      )

    }
  }

  depends_on = [
    aws_cloudwatch_log_group.self_healing
  ]

  tags = {
    Name        = "${var.environment}-self-healing-controller"
    Environment = var.environment
  }
}