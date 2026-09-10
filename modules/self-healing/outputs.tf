output "lambda_function_name" {
  value = aws_lambda_function.self_healing.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.self_healing.arn
}