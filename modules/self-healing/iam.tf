# ============================================================
# Lambda execution role
# ============================================================

resource "aws_iam_role" "self_healing" {
  name = "${var.environment}-self-healing-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-self-healing-lambda-role"
    Environment = var.environment
  }
}


# ============================================================
# Lambda permissions
# ============================================================

resource "aws_iam_role_policy" "self_healing" {
  name = "${var.environment}-self-healing-policy"

  role = aws_iam_role.self_healing.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      # ------------------------------------------------------
      # ECS
      # ------------------------------------------------------

      {
        Effect = "Allow"

        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:UpdateService",
          "ecs:StopTask"
        ]

        Resource = "*"
      },

      # ------------------------------------------------------
      # ALB
      # ------------------------------------------------------

      {
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:DescribeTargetHealth"
        ]

        Resource = "*"
      },

      # ------------------------------------------------------
      # CloudWatch
      # ------------------------------------------------------

      {
        Effect = "Allow"

        Action = [
          "cloudwatch:DescribeAlarms"
        ]

        Resource = "*"
      },

      # ------------------------------------------------------
      # EventBridge Scheduler
      # ------------------------------------------------------

      {
        Effect = "Allow"

        Action = [
          "scheduler:CreateSchedule"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = "${aws_iam_role.scheduler_execution.arn}"
      },
      # ------------------------------------------------------
      # CloudWatch Logs
      # ------------------------------------------------------

      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })
}


# ============================================================
# Scheduler execution role
# ============================================================

resource "aws_iam_role" "scheduler_execution" {
  name = "${var.environment}-self-healing-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "scheduler.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-self-healing-scheduler-role"
    Environment = var.environment
  }
}


# ============================================================
# Scheduler → Lambda permission
# ============================================================

resource "aws_iam_role_policy" "scheduler_execution" {
  name = "${var.environment}-scheduler-lambda-policy"

  role = aws_iam_role.scheduler_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "lambda:InvokeFunction"
        ]

        Resource = aws_lambda_function.self_healing.arn
      }
    ]
  })
}