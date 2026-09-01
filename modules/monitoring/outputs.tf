output "sns_topic_arn" {
  description = "The ARN of the SNS topic for CloudWatch alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "The name of the SNS topic"
  value       = aws_sns_topic.alerts.name
}

output "ecs_cpu_alarm_arn" {
  description = "The ARN of the ECS CPU High CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
}

output "alb_5xx_alarm_arn" {
  description = "The ARN of the ALB 5XX Errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
}