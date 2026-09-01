output "repository_url" {
  description = "The repository URL where Docker images are pushed"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.app.name
}