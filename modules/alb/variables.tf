variable "environment" {
  type        = string
  description = "Deployment environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ALB and target groups will be deployed"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs to attach to the Application Load Balancer"
}

variable "container_port" {
  type        = number
  description = "Port on which the application container listens for HTTP traffic"
  default     = 8080
}