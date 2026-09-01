provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "3-Tier-App"
    }
  }
}

# 1. IAM Execution Role for ECS Tasks
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. VPC Module
module "vpc" {
  source        = "../../modules/vpc"
  environment   = var.environment
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_cidrs
  private_cidrs = var.private_cidrs
  db_cidrs      = var.db_cidrs
  azs           = var.azs
}

# 3. ALB Module
module "alb" {
  source            = "../../modules/alb"
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = var.container_port
}

# 4. ECR Module
module "ecr" {
  source          = "../../modules/ecr"
  environment     = var.environment
  repository_name = "web-app"
}

# 5. RDS Module
module "rds" {
  source        = "../../modules/rds"
  environment   = var.environment
  vpc_id        = module.vpc.vpc_id
  db_subnet_ids = module.vpc.db_subnet_ids
  ecs_sg_id     = module.ecs.ecs_sg_id
  db_name       = var.db_name
  db_user       = var.db_user
}

# 6. ECS Module
module "ecs" {
  source              = "../../modules/ecs"
  environment         = var.environment
  region              = var.region
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  alb_sg_id           = module.alb.alb_sg_id
  target_group_arn    = module.alb.target_group_arn
  container_image     = "${module.ecr.repository_url}:latest"
  container_port      = var.container_port
  execution_role_arn  = aws_iam_role.ecs_execution_role.arn
  execution_role_name = aws_iam_role.ecs_execution_role.name
  db_secret_arn       = module.rds.db_secret_arn
}