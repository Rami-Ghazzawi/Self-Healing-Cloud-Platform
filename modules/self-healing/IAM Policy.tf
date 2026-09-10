resource "aws_iam_role_policy" "self_healing_lambda" {
  name = "dev-self-healing-lambda-policy"
role = aws_iam_role.self_healing.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      # ECS permissions
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

      # CloudWatch Logs
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