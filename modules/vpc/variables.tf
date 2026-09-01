variable "environment" {
  type        = string
  description = "Deployment environment name (e.g., dev, staging, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "The primary IPv4 CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets (ALB, NAT Gateways)"
}

variable "private_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private application subnets (ECS Fargate tasks)"
}

variable "db_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for isolated database subnets (RDS)"
}

variable "azs" {
  type        = list(string)
  description = "List of Availability Zones to distribute subnets across"
}