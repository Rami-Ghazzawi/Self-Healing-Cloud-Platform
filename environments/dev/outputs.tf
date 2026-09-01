output "alb_public_dns" {
  description = "Public HTTP endpoint URL of the Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "Target ECR image repository URI"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "Internal database connection endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_credentials_secret_arn" {
  description = "Secrets Manager secret ARN containing DB user & password"
  value       = module.rds.db_secret_arn
}

output "ecs_cluster_name" {
  description = "ECS Fargate Cluster name"
  value       = module.ecs.cluster_name
}

output "nat_gateway_ip" {
  description = "Egress public IP address for outgoing container connections"
  value       = module.vpc.nat_gateway_ip
}