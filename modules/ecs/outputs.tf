output "cluster_id" {
  description = "ID of the ECS Cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "Name of the deployed ECS Service"
  value       = aws_ecs_service.main.name
}

output "ecs_sg_id" {
  description = "ID of the Security Group assigned to ECS Fargate tasks"
  value       = aws_security_group.ecs_tasks.id
}