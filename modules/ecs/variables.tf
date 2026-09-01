variable "environment" {
  type        = string
  description = "Deployment environment name"
}

variable "region" {
  type        = string
  description = "AWS region where CloudWatch log streams will be published"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ECS tasks and security groups reside"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where Fargate tasks will run"
}

variable "alb_sg_id" {
  type        = string
  description = "Security Group ID of the ALB to permit inbound traffic"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB Target Group to attach ECS tasks to"
}

variable "container_image" {
  type        = string
  description = "Full URI of the container image in ECR (including tag)"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the Docker container"
  default     = 8080
}

variable "execution_role_arn" {
  type        = string
  description = "IAM Role ARN used by ECS agent to pull images and push logs"
}

variable "execution_role_name" {
  type        = string
  description = "IAM Role Name used by ECS agent (needed for inline policy attachment)"
}

variable "task_role_arn" {
  type        = string
  description = "IAM Role ARN assumed by the container at runtime"
  default     = null
}

variable "db_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret storing DB credentials to inject"
}