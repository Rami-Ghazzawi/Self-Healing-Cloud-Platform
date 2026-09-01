variable "environment" {
  type        = string
  description = "Target deployment environment"
  default     = "dev"
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blocks for ALB and NAT Gateways"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_cidrs" {
  type        = list(string)
  description = "Private subnet CIDR blocks for ECS container tasks"
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "db_cidrs" {
  type        = list(string)
  description = "Isolated database subnet CIDR blocks for RDS"
  default     = ["10.0.100.0/24", "10.0.200.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to distribute resources across"
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "container_port" {
  type        = number
  description = "Port exposed by the application container"
  default     = 8080
}

variable "app_image_tag" {
  type    = string
  default = "latest"
}

variable "db_name" {
  type        = string
  description = "Initial PostgreSQL database name"
  default     = "appdb"
}

variable "db_user" {
  type        = string
  description = "Master database user account name"
  default     = "dbadmin"
}
