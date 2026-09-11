# Deployment Guide

## 1. Prerequisites

Ensure the following tools are installed and configured:

- AWS CLI
- Terraform
- Docker
- Git

Verify the installations:

```bash
aws --version
terraform --version
docker --version
git --version
```

---

## 2. Configure AWS Credentials

Ensure the AWS CLI is authenticated to the target AWS account:

```bash
aws sts get-caller-identity
```

The command should return the AWS account and IAM identity being used.

---

## 3. Infrastructure Provisioning

### 3.1 Navigate to the Environment Directory

```bash
cd environments/dev
```

### 3.2 Initialize Terraform

Initialize the Terraform working directory and download the required providers:

```bash
terraform init
```

### 3.3 Review the Deployment Plan

Validate the Terraform configuration and review the resources that will be provisioned:

```bash
terraform plan
```

### 3.4 Deploy the Infrastructure

Provision the required AWS infrastructure, including the VPC, ECS, RDS, ALB, ECR, monitoring, alarms, and self-healing components:

```bash
terraform apply -auto-approve
```

---

## 4. Application Build & Initial Deployment

After the infrastructure has been provisioned, build the application container and push it to Amazon ECR.

### 4.1 Authenticate Docker to Amazon ECR

Replace `<AWS_ACCOUNT_ID>` with the AWS account ID:

```bash
aws ecr get-login-password --region eu-west-2 | \
docker login --username AWS --password-stdin \
<AWS_ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com
```

### 4.2 Build the Docker Image

From the application directory:

```bash
docker build -t dev-app .
```

### 4.3 Tag the Docker Image

```bash
docker tag dev-app:latest \
<AWS_ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com/dev-app:latest
```

### 4.4 Push the Image to Amazon ECR

```bash
docker push \
<AWS_ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com/dev-app:latest
```

---

## 5. CI/CD Pipeline Setup

The project uses GitHub Actions to automate application validation and deployment.

Navigate to:

**GitHub Repository → Settings → Secrets and variables → Actions**

Add the following repository secrets:

| Secret                  | Description                             |
| ----------------------- | --------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | AWS IAM access key                      |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret access key               |
| `AWS_REGION`            | AWS deployment region, e.g. `eu-west-2` |
| `ECR_REPOSITORY`        | ECR repository name, e.g. `dev-app`     |

Once configured, pushing changes to the repository will trigger the CI/CD workflows.

---

## 6. Deployment Verification

After deployment, verify that the application and infrastructure are operating correctly.

### 6.1 Retrieve the ALB DNS Name

```bash
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[0].DNSName" \
  --output text
```

### 6.2 Verify the Application Health Endpoint

Replace `<ALB_DNS_NAME>` with the DNS name returned above:

```bash
curl http://<ALB_DNS_NAME>/health
```

Expected response:

```json
{ "status": "healthy" }
```

### 6.3 Verify ECS Service Health

Check the running ECS tasks:

```bash
aws ecs list-tasks \
  --cluster dev-ecs-cluster
```

The expected result is that the ECS service has its desired number of healthy running tasks.

---

## 7. Resource Cleanup

To avoid unnecessary AWS charges when testing is complete, destroy the provisioned infrastructure:

```bash
cd environments/dev

terraform destroy -auto-approve
```

This removes the Terraform-managed AWS resources created for the development environment.
