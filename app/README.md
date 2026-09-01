# Self-Healing Task Manager

A production-style 3-tier web application built for an AWS Cloud/DevOps project.

The application is designed to run on:

- AWS ECS Fargate
- Application Load Balancer
- Amazon RDS PostgreSQL
- Amazon ECR
- AWS Secrets Manager
- Terraform
- CloudWatch

## Architecture

Internet
    |
    v
Application Load Balancer
    |
    | HTTP :8080
    v
ECS Fargate
    |
    | PostgreSQL :5432
    v
Amazon RDS PostgreSQL

## Application Stack

- Node.js
- Express
- PostgreSQL
- Docker
- AWS ECS Fargate

## Features

- Create tasks
- List tasks
- Get a task
- Update tasks
- Complete/uncomplete tasks
- Delete tasks
- PostgreSQL persistence
- Health monitoring endpoint
- Docker containerization

## API Endpoints

### Health

GET /health

Example response:

{
  "status": "healthy",
  "service": "task-manager",
  "database": "connected"
}

### List Tasks

GET /api/tasks

### Get Task

GET /api/tasks/:id

### Create Task

POST /api/tasks

Request:

{
  "title": "Learn Terraform",
  "description": "Build AWS infrastructure with Terraform"
}

### Update Task

PATCH /api/tasks/:id

Request:

{
  "completed": true
}

### Delete Task

DELETE /api/tasks/:id

## Environment Variables

The application expects:

DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=dbadmin
DB_PASSWORD=your-password
PORT=8080

In AWS, database credentials should be provided through AWS Secrets Manager rather than hardcoded values.

## Run Locally

Install dependencies:

npm install

Set the required environment variables.

Example:

export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=appdb
export DB_USER=dbadmin
export DB_PASSWORD=your-password
export PORT=8080

Start the application:

npm start

The application will be available at:

http://localhost:8080

Health check:

curl http://localhost:8080/health

## Docker

Build the image:

docker build -t self-healing-task-manager .

Run the container:

docker run --rm \
  -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=appdb \
  -e DB_USER=dbadmin \
  -e DB_PASSWORD=your-password \
  self-healing-task-manager

Test:

curl http://localhost:8080/health

## AWS Deployment

The application is designed to be deployed using:

Terraform
    |
    +-- VPC
    +-- ALB
    +-- ECS Fargate
    +-- ECR
    +-- RDS PostgreSQL
    +-- Secrets Manager
    +-- IAM
    +-- Security Groups

The Docker image is pushed to Amazon ECR and then deployed through ECS Fargate.

## Self-Healing Design

The application exposes:

GET /health

The Application Load Balancer uses this endpoint as its health check.

If an ECS task becomes unhealthy:

1. ALB detects the unhealthy task.
2. ECS maintains the desired task count.
3. The unhealthy task is replaced.
4. A new task starts.
5. The new task registers with the ALB.
6. Traffic is routed to the healthy task.

This provides the foundation for the project's self-healing architecture.

## Project Goals

This project demonstrates practical knowledge of:

- AWS
- Cloud Architecture
- Terraform
- Infrastructure as Code
- Docker
- ECS Fargate
- Application Load Balancing
- PostgreSQL
- Secrets Management
- IAM
- Networking
- Health Checks
- Self-Healing Infrastructure
- CI/CD
- Monitoring and Alerting

## Future Improvements

- GitHub Actions CI/CD
- CloudWatch dashboards
- CloudWatch alarms
- SNS notifications
- Automated deployments
- Blue/Green deployments
- Auto Scaling
- HTTPS with ACM
- Route 53
- WAF
- Centralized logging
- Distributed tracing