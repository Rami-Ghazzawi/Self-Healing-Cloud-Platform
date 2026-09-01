variable "environment" {
  type        = string
  description = "Deployment environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where database security group will be created"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "List of isolated database subnet IDs"
}

variable "ecs_sg_id" {
  type        = string
  description = "Security Group ID of the ECS tasks allowed to connect to RDS"
}

variable "db_name" {
  type        = string
  description = "Initial database name created on database instance launch"
  default     = "appdb"
}

variable "db_user" {
  type        = string
  description = "Master username for the RDS PostgreSQL database"
  default     = "dbadmin"
}
