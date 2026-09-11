# Autonomous Self-Healing Cloud Platform

## 1. Overview

The **Autonomous Self-Healing Cloud Platform** is a production-style cloud infrastructure project designed to automatically detect infrastructure and application failures, perform controlled recovery actions, and verify that the system has successfully recovered.

The platform is built on **Amazon Web Services (AWS)** and uses an event-driven architecture combining containerized workloads, centralized monitoring, infrastructure as code, and automated recovery.

The main goal of the project is to demonstrate how cloud infrastructure can move beyond simple monitoring and alerting toward **autonomous failure detection and controlled recovery**.

---

## 2. Objectives

The platform was designed to achieve the following objectives:

- Deploy a containerized application using AWS ECS Fargate.
- Provide application traffic through an Application Load Balancer.
- Store persistent application data in Amazon RDS PostgreSQL.
- Monitor infrastructure health using Amazon CloudWatch.
- Detect abnormal CPU, memory, and HTTP error conditions.
- Automatically trigger recovery actions when predefined failure conditions occur.
- Enforce explicit safety boundaries on automated recovery.
- Verify that recovery actions actually restore the system to a healthy state.
- Provision the infrastructure using Terraform.
- Automate application delivery using GitHub Actions.

---

## 3. Architecture

The platform follows an event-driven self-healing architecture.

```text
                           ┌───────────────┐
                           │     Users     │
                           └───────┬───────┘
                                   │
                                   ▼
                         ┌──────────────────┐
                         │ Application      │
                         │ Load Balancer    │
                         └────────┬─────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │       ECS Fargate       │
                    │                         │
                    │  ┌───────┐  ┌───────┐   │
                    │  │ Task  │  │ Task  │   │
                    │  │ App   │  │ App   │   │
                    │  └───────┘  └───────┘   │
                    └──────────┬──────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
                    ▼                     ▼
             ┌─────────────┐       ┌─────────────┐
             │ RDS         │       │ CloudWatch  │
             │ PostgreSQL  │       │ Monitoring  │
             └─────────────┘       └──────┬──────┘
                                          │
                                   Alarm triggered
                                          │
                                          ▼
                                  ┌───────────────┐
                                  │  EventBridge  │
                                  └───────┬───────┘
                                          │
                                          ▼
                                  ┌───────────────┐
                                  │ Self-Healing  │
                                  │    Lambda     │
                                  └───────┬───────┘
                                          │
                               Controlled recovery
                                          │
                                          ▼
                                  ┌───────────────┐
                                  │ ECS / ALB     │
                                  │ Recovery      │
                                  └───────┬───────┘
                                          │
                                          ▼
                                  Recovery verified
```

The infrastructure is provisioned using Terraform modules for:

- VPC networking
- Application Load Balancer
- Amazon ECR
- Amazon ECS
- Amazon RDS
- CloudWatch monitoring
- Self-healing automation

---

## 4. Technology Stack

| Category                | Technology                |
| ----------------------- | ------------------------- |
| Cloud Provider          | AWS                       |
| Infrastructure as Code  | Terraform                 |
| Container Platform      | Docker                    |
| Container Orchestration | Amazon ECS Fargate        |
| Container Registry      | Amazon ECR                |
| Load Balancing          | Application Load Balancer |
| Database                | Amazon RDS PostgreSQL     |
| Monitoring              | Amazon CloudWatch         |
| Event Routing           | Amazon EventBridge        |
| Notifications           | Amazon SNS                |
| Automation              | AWS Lambda                |
| CI/CD                   | GitHub Actions            |
| Application             | Node.js / Express         |
| Runtime Automation      | Python / Bash             |
| Networking              | Amazon VPC                |

---

## 5. Infrastructure Modules

The Terraform infrastructure is organized into reusable modules.

```text
modules/
├── alb/
├── ecr/
├── ecs/
├── monitoring/
├── rds/
├── self-healing/
└── vpc/
```

### VPC

Provides the networking foundation for the platform, including the network environment required by the application and database components.

### ALB

Provides public HTTP access to the application and distributes traffic across healthy ECS tasks.

### ECR

Stores the Docker images used by the ECS application.

### ECS

Runs the containerized application using Amazon ECS Fargate.

### RDS

Provides persistent PostgreSQL database storage for the application.

### Monitoring

Defines CloudWatch metrics and alarms used to observe the health of the infrastructure.

### Self-Healing

Contains the autonomous recovery mechanism, including:

- AWS Lambda
- EventBridge rules
- SNS integration
- IAM roles and policies
- CloudWatch logging
- Recovery scheduling

---

## 6. Monitoring and Observability

Amazon CloudWatch is used as the primary monitoring system.

The platform monitors signals including:

- ECS CPU utilization
- ECS memory utilization
- Live task count
- Application Load Balancer HTTP 5XX errors

When a monitored condition exceeds its configured threshold, CloudWatch changes the corresponding alarm state.

The alarm event is then processed by the event-driven recovery system.

Monitoring is therefore separated from recovery:

```text
CloudWatch
    │
    │ Detect
    ▼
Alarm
    │
    │ Event
    ▼
EventBridge
    │
    │ Trigger
    ▼
Self-Healing Lambda
```

---

## 7. Self-Healing Mechanism

The core of the platform is the **Self-Healing Controller**, implemented as an AWS Lambda function.

The controller receives events associated with infrastructure health conditions and determines whether a controlled recovery action should be performed.

The recovery process follows this general flow:

```text
Failure Condition
       │
       ▼
CloudWatch Alarm
       │
       ▼
EventBridge
       │
       ▼
Self-Healing Lambda
       │
       ▼
Validate Recovery Conditions
       │
       ▼
Execute Controlled Action
       │
       ▼
Monitor Result
       │
       ▼
Recovery Confirmed
```

The controller is designed with explicit safety boundaries to prevent uncontrolled infrastructure changes.

Examples of controlled operations include ECS service and task management.

The Lambda execution role is restricted to the AWS operations required by the recovery mechanism.

---

## 8. Recovery Verification

Recovery is not considered successful simply because a recovery action was executed.

The platform verifies the resulting system state.

A successful recovery produces the following logical sequence:

```text
Alarm: ALARM
      │
      ▼
Recovery Action
      │
      ▼
System Stabilization
      │
      ▼
Alarm: OK
      │
      ▼
RECOVERY_CONFIRMED
```

The `RECOVERY_CONFIRMED` event provides explicit evidence that the controller observed a successful recovery state.

This distinction is important because **executing a recovery action and proving that recovery succeeded are two different operations**.

---

## 9. Safety Boundaries

Autonomous infrastructure operations must be constrained to prevent runaway recovery behavior.

The self-healing controller therefore operates within predefined boundaries.

The safety mechanism limits the scope of automated recovery and prevents the controller from continuously increasing resources without control.

This was validated through dedicated safe-boundary testing.

The objective is to ensure that:

```text
Failure
  ↓
Recovery
  ↓
Verification
```

does not become:

```text
Failure
  ↓
Unlimited Recovery
  ↓
Uncontrolled Resource Usage
```

---

## 10. Testing

The platform was tested using controlled failure scenarios.

### CPU Self-Healing Test

A sustained CPU load is introduced to the application environment.

Expected behavior:

```text
High CPU
   ↓
CloudWatch CPU Alarm
   ↓
EventBridge
   ↓
Self-Healing Lambda
   ↓
ECS Recovery Action
   ↓
System Stabilization
```

### Safe Boundary Test

The test verifies that the self-healing controller cannot exceed its configured recovery limits.

### Recovery Test

The test verifies that the controller performs the expected recovery action after a failure condition is detected.

### Recovery Verification Test

The final system state is verified to ensure that the recovery was actually successful.

The controller logs:

```text
RECOVERY_CONFIRMED
```

when recovery has been successfully verified.

---

## 11. CI/CD

The project uses GitHub Actions to automate the software delivery workflow.

The CI pipeline validates the application and infrastructure changes before deployment.

The deployment workflow builds the application container, publishes the image to Amazon ECR, and updates the ECS service.

The general workflow is:

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ├── Application Validation
   ├── Docker Build
```

## 12. Setup & Deployment Guide

This guide provides step-by-step instructions for deploying the **Autonomous Self-Healing Cloud Platform** using Terraform and GitHub Actions.

---

## 1. Prerequisites

Before you begin, ensure you have the following installed and configured on your local machine:

- **Git**: [Install Git](https://git-scm.com/)
- **Terraform** (`>= 1.5.0`): [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI** (`>= 2.0`): [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with valid credentials (`aws configure`).
- **Docker**: [Install Docker Desktop](https://www.docker.com/products/docker-desktop/) (required for building and pushing images).
- **Node.js** (`>= 20.x`): [Install Node.js](https://nodejs.org/) (for local application validation).

---

## 2. Local Environment Setup

### 1. Clone the Repository

```bash
git clone [https://github.com/your-username/self-healing-cloud-platform.git](https://github.com/your-username/self-healing-cloud-platform.git)
cd self-healing-cloud-platform
```

**More Details in "deployment.md" file"**
