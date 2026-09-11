# CI/CD Pipeline

## 1. Overview

The project uses a GitHub Actions-based CI/CD pipeline to automate application validation, Docker image building, container image publishing, infrastructure validation, and ECS deployment.

The pipeline is triggered by changes pushed to the repository.

```text
Git Push
   ↓
GitHub Actions
   ↓
CI
├── Checkout
├── Node dependency validation
├── Docker Build
├── Terraform Init
├── Terraform Format
└── Terraform Validate
   ↓
CD
   ↓
Docker Image
   ↓
Amazon ECR
   ↓
Amazon ECS Deployment
   ↓
Health Verification
```

The pipeline separates **Continuous Integration (CI)** from **Continuous Deployment (CD)**. CI verifies that the application and infrastructure configuration are valid, while CD publishes the container image and deploys the updated application to Amazon ECS.

---

## 2. CI Workflow

The Continuous Integration stage runs automated checks before deployment.

The workflow performs the following operations:

### 2.1 Repository Checkout

GitHub Actions checks out the latest repository revision so that the workflow can access the application source code, Dockerfile, and Terraform configuration.

### 2.2 Node Dependency Validation

The application dependencies are validated using the Node.js package configuration.

The workflow uses the project's `package-lock.json` to ensure reproducible dependency installation.

### 2.3 Docker Build

The application Docker image is built during CI.

This verifies that the Dockerfile is valid and that the application can be packaged successfully into a production container image.

### 2.4 Terraform Initialization

Terraform is initialized to download the required providers and prepare the working directory.

```bash
terraform init
```

### 2.5 Terraform Format Check

The Terraform configuration is checked for formatting consistency.

```bash
terraform fmt -check
```

This prevents incorrectly formatted Terraform files from progressing through the pipeline.

### 2.6 Terraform Validation

Terraform configuration is validated for structural and configuration errors.

```bash
terraform validate
```

The validation stage helps detect infrastructure configuration problems before deployment.

---

## 3. Docker Build

The application is packaged as a Docker image using the project's Dockerfile.

The container provides the runtime environment for the Node.js application and exposes port `8080`.

The Docker build performed during CI ensures that the application can be successfully converted into a deployable container image.

The image is subsequently tagged and prepared for publishing to Amazon Elastic Container Registry (ECR).

---

## 4. ECR Image Publishing

After the CI stage succeeds, the Docker image is published to Amazon ECR.

The deployment process follows:

```text
Application Source
       ↓
Docker Build
       ↓
Docker Image
       ↓
Amazon ECR
       ↓
ECS Task Definition
```

Amazon ECR acts as the private container registry for the project.

ECS retrieves the image from ECR when deploying the application tasks.

Using ECR provides a centralized and versionable location for the container images used by the ECS service.

---

## 5. ECS Deployment

After the image is successfully published to ECR, the CD stage deploys the updated container image to Amazon ECS.

The application runs on:

- **Amazon ECS**
- **AWS Fargate**
- ECS Cluster: `dev-ecs-cluster`
- ECS Service: `dev-service`

The ECS service manages the running application tasks and maintains the configured desired task count.

The deployment process updates the running application with the newly published container image.

The Application Load Balancer continues to provide traffic distribution and health checking for the ECS tasks.

```text
GitHub Actions
      ↓
     ECR
      ↓
ECS Service
      ↓
Fargate Tasks
      ↓
Application Load Balancer
      ↓
Users
```

---

## 6. Deployment Verification

After deployment, the application is verified through the ECS and Application Load Balancer health mechanisms.

The application exposes a health endpoint:

```text
/health
```

The Application Load Balancer uses this endpoint to determine whether ECS tasks are healthy.

A successful deployment therefore requires the newly deployed tasks to become healthy and available through the load balancer.

The verification process provides an additional layer of protection against deploying a container that starts successfully but cannot serve application traffic correctly.

---

## 7. Rollback Considerations

The current pipeline does not implement a custom automated rollback mechanism.

ECS deployment and service health mechanisms provide the first level of protection by monitoring the health of the deployed tasks.

If a deployment introduces an application failure, the unhealthy ECS tasks can be identified through ECS and ALB health checks.

A future version of the pipeline could implement automated rollback based on deployment health signals.

Possible improvements include:

- Automatic rollback when ECS tasks fail health checks
- Monitoring deployment failure states
- Automatic restoration of the previous image version
- Integration with CloudWatch alarms
- Deployment strategies such as blue/green deployments

Rollback is intentionally treated as a future enhancement rather than being presented as an implemented feature.

---

## 8. Security Considerations

The CI/CD pipeline interacts with AWS infrastructure and therefore requires controlled access to AWS resources.

The deployment process should follow the principle of least privilege and avoid exposing long-lived AWS credentials unnecessarily.

The infrastructure itself also separates application execution permissions from deployment permissions.

Sensitive application configuration, such as database credentials, is not stored directly in the application source code. Database credentials are managed through **AWS Secrets Manager** and provided to the ECS application securely.

The container image is stored in a private Amazon ECR repository.

Additional security controls include:

- Private ECR image storage
- IAM-based access control
- Secrets Manager for sensitive credentials
- Restricted ECS task permissions
- Controlled AWS deployment permissions
- No credentials committed to the Git repository

---

## 9. Future Improvement: GitHub OIDC

The current deployment configuration uses AWS credentials configured for GitHub Actions.

A future improvement is to replace long-lived AWS access keys with **GitHub Actions OpenID Connect (OIDC)**.

With OIDC, GitHub Actions can authenticate to AWS using short-lived credentials through an IAM role.

The intended architecture would become:

```text
GitHub Actions
      │
      │ OIDC
      ▼
AWS IAM Role
      │
      ▼
Temporary AWS Credentials
      │
      ▼
ECR / ECS / AWS Resources
```

This would eliminate the need to store long-lived AWS access keys as GitHub secrets and would provide a more secure and maintainable authentication model.

The OIDC implementation is considered a future security improvement for the project.
