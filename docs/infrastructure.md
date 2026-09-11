# Infrastructure

## 1. Terraform Architecture

The infrastructure is provisioned and managed using Terraform.

The project follows a modular Terraform architecture where each major AWS component is implemented as an independent module.

The development environment composes these modules together:

```text
environments/dev
        │
        ├── VPC
        ├── ALB
        ├── ECS
        ├── ECR
        ├── RDS
        ├── Monitoring
        └── Self-Healing
```

This structure keeps infrastructure components separated and makes the configuration easier to maintain, reuse, and extend.

---

## 2. Module Structure

The project currently uses the following Terraform modules:

```text
modules/
├── vpc/
├── alb/
├── ecs/
├── ecr/
├── rds/
├── monitoring/
└── self-healing/
```

Each module is responsible for provisioning and configuring a specific part of the platform.

The `self-healing` module contains the autonomous recovery controller and its supporting EventBridge, IAM, Lambda, and scheduling resources.

The development environment is defined under:

```text
environments/dev/
```

This environment connects the individual modules and provides their environment-specific configuration.

---

## 3. VPC

The VPC provides the network foundation for the AWS infrastructure.

The architecture separates public and private resources according to their networking requirements.

The public layer is used for components that need controlled external access, such as the Application Load Balancer.

Private resources, including the RDS database, are isolated from direct public access.

The general traffic flow is:

```text
Internet
   ↓
Public Subnets
   ↓
Application Load Balancer
   ↓
Private Application Resources
   ↓
Private Database
```

This separation reduces the exposure of internal infrastructure while allowing the application to receive traffic through the load balancer.

---

## 4. ECS Fargate

The application runs on Amazon ECS using AWS Fargate.

The development environment uses:

```text
Cluster: dev-ecs-cluster
Service: dev-service
```

The ECS service manages the application's running tasks and maintains the desired number of instances.

The current task configuration uses:

```text
CPU:    256
Memory: 512 MB
Port:   8080
```

The application container exposes port `8080`, while the Application Load Balancer forwards application traffic to the ECS tasks.

Fargate removes the need to manage EC2 instances for the container workload and allows the project to focus on the application and infrastructure configuration.

---

## 5. ECR

Amazon Elastic Container Registry (ECR) is used as the private container registry for the application.

The CI/CD pipeline builds the Docker image and publishes it to ECR.

The deployment flow is:

```text
GitHub
   ↓
GitHub Actions
   ↓
Docker Build
   ↓
Amazon ECR
   ↓
Amazon ECS
```

ECR provides a centralized location for the container image used by ECS deployments.

---

## 6. ALB

An Application Load Balancer provides the entry point for application traffic.

The ALB distributes incoming requests across healthy ECS tasks.

The application uses port `8080`, and the ALB performs health checks against:

```text
/health
```

The health-check mechanism allows unhealthy targets to be identified and removed from normal traffic routing.

The ALB also provides an important monitoring signal for the self-healing system through the `HTTPCode_Target_5XX_Count` metric.

---

## 7. RDS

Amazon RDS provides the relational database layer.

The project uses PostgreSQL:

```text
Engine: PostgreSQL 15
Instance: db.t4g.micro
```

The database is deployed in the private network layer and is not directly exposed to the public internet.

The application communicates with the database through the private AWS network.

This creates a separation between:

```text
Public Traffic
      ↓
     ALB
      ↓
    ECS
      ↓
    RDS
```

Database credentials are not hard-coded into the application source code and are managed through AWS Secrets Manager.

---

## 8. Secrets Manager

AWS Secrets Manager is used to securely manage sensitive database credentials.

Instead of storing database credentials directly in Terraform configuration or application source code, the credentials are stored as a managed AWS secret.

The ECS application retrieves the required database credentials through the configured secret integration.

This reduces the risk of accidentally exposing sensitive credentials through source control.

---

## 9. IAM

AWS Identity and Access Management (IAM) controls access between the infrastructure components.

The project uses dedicated IAM roles for different services instead of relying on a single broad-access role.

Important roles include:

```text
ECS Task Role
Self-Healing Lambda Role
Self-Healing Scheduler Execution Role
```

The Self-Healing Lambda role provides the permissions required to inspect and modify ECS resources, inspect ALB target health, inspect CloudWatch alarms, and create verification schedules.

The Scheduler execution role is responsible for invoking the Self-Healing Lambda during scheduled verification.

IAM permissions are designed around the principle of least privilege where practical.

---

## 10. Terraform State

Terraform state is used to track the resources managed by Terraform.

The development environment maintains its Terraform state under:

```text
environments/dev/
```

Terraform state allows Terraform to determine which AWS resources already exist and what changes are required during subsequent operations.

The state should be treated as sensitive infrastructure data because it can contain resource metadata and configuration information.

Terraform state files should therefore not be committed to public source control.

---

## 11. Environment Configuration

The project separates environment-specific configuration from reusable infrastructure modules.

The current environment is:

```text
environments/dev/
```

The environment is responsible for composing the Terraform modules and providing configuration values such as:

- AWS region
- Environment name
- ECS configuration
- Database configuration
- Monitoring thresholds
- Self-healing parameters

This structure makes it possible to introduce additional environments, such as staging or production, without duplicating the underlying Terraform modules.

For example:

```text
environments/
├── dev/
├── staging/
└── prod/
```

The current project primarily uses the `dev` environment for development and testing.

---

## 12. Deployment / Destroy Workflow

Terraform is used to create, update, and destroy the infrastructure.

A typical deployment workflow is:

```text
Terraform Init
      ↓
Terraform Plan
      ↓
Terraform Apply
      ↓
AWS Infrastructure
```

Before applying infrastructure changes, Terraform configuration can be checked using:

```bash
terraform fmt
terraform validate
terraform plan
```

The infrastructure can then be provisioned using:

```bash
terraform apply
```

When the environment is no longer required, the resources can be removed using:

```bash
terraform destroy
```

Destroying the development environment is particularly useful for this project because several AWS resources can generate ongoing costs.

The destroy workflow allows the development infrastructure to be temporarily removed when testing is complete and recreated when further development or testing is required.

This approach helps control AWS costs while maintaining the infrastructure as reproducible Terraform code.
