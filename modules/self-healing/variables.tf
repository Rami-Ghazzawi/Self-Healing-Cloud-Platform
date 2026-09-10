variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecs_cluster" {
  type = string
}

variable "ecs_service" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "min_tasks" {
  type    = number
  default = 2
}

variable "max_tasks" {
  type    = number
  default = 5
}

variable "cpu_scale_increment" {
  type    = number
  default = 1
}

variable "max_retries" {
  type    = number
  default = 3
}

variable "cooldown_seconds" {
  type    = number
  default = 120
}