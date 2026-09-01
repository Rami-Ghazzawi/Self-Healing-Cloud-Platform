variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster to monitor"
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "The ARN suffix of the ALB (used for CloudWatch metrics dimension)"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU utilization threshold percentage to trigger alarm"
  type        = number
  default     = 80
}

variable "alb_5xx_threshold" {
  description = "Number of 5XX errors threshold to trigger alarm"
  type        = number
  default     = 10
}