output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "The hostname address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "rds_sg_id" {
  description = "ID of the Security Group attached to the RDS instance"
  value       = aws_security_group.rds.id
}

output "db_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret holding DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}