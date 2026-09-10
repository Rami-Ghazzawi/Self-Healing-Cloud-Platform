# Autonomous Self-Healing Cloud Platform

An AWS-based cloud platform designed to automatically detect infrastructure and application health issues, perform controlled recovery actions, verify recovery, and escalate when automated healing reaches its safety limits.

The platform combines Infrastructure as Code, containerization, CI/CD, centralized monitoring, event-driven automation, and controlled chaos testing.

---

## 1. Project Overview

Modern cloud applications must remain available even when individual components experience failures or resource exhaustion.

This project implements an autonomous self-healing mechanism on AWS that continuously observes the health of a containerized application and reacts to predefined failure conditions.

The platform follows this general lifecycle:

```text
Deploy
  ↓
Observe
  ↓
Detect
  ↓
Decide
  ↓
Heal
  ↓
Verify
  ↓
Recover
  ↓
Escalate if necessary
```

The primary goal is not simply to restart failed containers, but to demonstrate a controlled automation loop that can:

- Detect abnormal conditions
- Identify the appropriate recovery action
- Apply bounded corrective actions
- Avoid uncontrolled scaling
- Verify whether recovery succeeded
- Retry when appropriate
- Escalate when automated recovery is no longer safe

---

## 2. Architecture

The platform is deployed on AWS using Terraform.

### High-Level Architecture

```text
                         Internet
                            │
                            ▼
                     ┌─────────────┐
                     │     ALB     │
                     └──────┬──────┘
                            │
                            ▼
                 ┌────────────────────┐
                 │    ECS Fargate     │
                 │                    │
                 │  ┌──────┐ ┌──────┐ │
                 │  │Task 1│ │Task 2│ │
                 │  └──────┘ └──────┘ │
                 │       + scaling     │
                 └─────────┬──────────┘
                           │
                 ┌─────────┴─────────┐
                 │                   │
                 ▼                   ▼
          ┌────────────┐      ┌────────────┐
          │ RDS        │      │ Secrets    │
          │ PostgreSQL │      │ Manager    │
          └────────────┘      └────────────┘

                 Monitoring Layer
                        │
                        ▼
                 ┌─────────────┐
                 │ CloudWatch  │
                 └──────┬──────┘
                        │
                        ▼
                 ┌─────────────┐
                 │ EventBridge │
                 └──────┬──────┘
                        │
                        ▼
                 ┌─────────────┐
                 │   Lambda    │
                 │ Self-Healing│
                 └──────┬──────┘
                        │
              ┌─────────┼─────────┐
              ▼         ▼         ▼
             ECS       ALB      Scheduler
```

Detailed architecture documentation is available in:

`docs/architecture.md`

---

## 3. Technology Stack

| Layer                  | Technology                      |
| ---------------------- | ------------------------------- |
| Cloud Provider         | AWS                             |
| Infrastructure as Code | Terraform                       |
| Containers             | Docker                          |
| Container Platform     | Amazon ECS Fargate              |
| Container Registry     | Amazon ECR                      |
| Load Balancer          | Application Load Balancer       |
| Database               | Amazon RDS PostgreSQL           |
| Secrets                | AWS Secrets Manager             |
| Monitoring             | Amazon CloudWatch               |
| Event Routing          | Amazon EventBridge              |
| Automation             | AWS Lambda                      |
| Scheduling             | EventBridge Scheduler           |
| CI/CD                  | GitHub Actions                  |
| Application            | Node.js / Express               |
| Testing                | Chaos Engineering + `stress-ng` |

---

## 4. Infrastructure

The infrastructure is provisioned using Terraform.

The project follows a modular structure:

```text
modules/
├── vpc/
├── alb/
├── ecr/
├── ecs/
├── rds/
└── monitoring/
```

The development environment is located under:

```text
environments/dev/
```

The infrastructure includes:

- VPC networking
- ECS cluster and service
- ECS Fargate tasks
- ECR repository
- Application Load Balancer
- RDS PostgreSQL
- Secrets Manager
- CloudWatch monitoring
- CloudWatch alarms
- EventBridge rules
- Self-healing Lambda
- IAM roles and policies
- EventBridge Scheduler

Detailed infrastructure documentation:

`docs/infrastructure.md`

---

## 5. Application

The platform runs a containerized Node.js/Express application.

The application exposes:

```text
GET /health
GET /api/tasks
```

The `/health` endpoint is used by the Application Load Balancer to determine whether an application task is healthy.

The application listens on:

```text
Port: 8080
```

The container image is stored in Amazon ECR.

---

## 6. CI/CD

GitHub Actions automates the build and deployment workflow.

### Continuous Integration

Pull requests and pushes trigger validation steps including:

```text
Checkout
   ↓
Install Dependencies
   ↓
Docker Build
   ↓
Terraform Init
   ↓
Terraform Format Check
   ↓
Terraform Validate
```

### Continuous Deployment

Changes merged to the deployment branch trigger:

```text
Git Push
   ↓
GitHub Actions
   ↓
Docker Build
   ↓
Push Image → ECR
   ↓
Update ECS Deployment
   ↓
New Fargate Tasks
   ↓
ALB Health Check
```

Detailed CI/CD documentation:

`docs/ci-cd.md`

---

## 7. Monitoring

Amazon CloudWatch provides observability into the ECS service.

The platform monitors metrics including:

- ECS CPU utilization
- ECS memory utilization
- Live task count
- ALB HTTP 5XX errors
- Application logs

CloudWatch alarms detect abnormal conditions.

Example CPU alarm:

```text
Metric:
ECS CPUUtilization

Threshold:
80%

Evaluation:
2 consecutive periods

Statistic:
Average
```

Monitoring documentation:

`docs/monitoring.md`

---

## 8. Self-Healing

The core of the project is an event-driven self-healing controller implemented using AWS Lambda.

The controller receives events generated from CloudWatch alarms through EventBridge.

```text
CloudWatch Alarm
       │
       ▼
  EventBridge
       │
       ▼
Self-Healing Lambda
       │
       ▼
   Diagnosis
       │
       ▼
Recovery Action
       │
       ▼
Verification
```

The controller supports controlled recovery actions such as:

- Scaling ECS service capacity
- Replacing unhealthy ECS tasks
- Inspecting ALB target health
- Retrying recovery
- Detecting successful recovery
- Escalating when safety limits are reached

The system does not blindly restart infrastructure.

Instead, it follows a decision-based recovery process.

Detailed documentation:

`docs/self-healing.md`

---

## 9. Safety Boundaries

Self-healing automation must have explicit limits.

The platform therefore enforces:

```text
MIN_TASKS = 2
MAX_TASKS = 5
CPU_SCALE_INCREMENT = 1
MAX_RETRIES = 3
COOLDOWN = 120 seconds
```

Example:

```text
2 tasks
   ↓
3 tasks
   ↓
4 tasks
   ↓
5 tasks
   ↓
MAXIMUM REACHED
   ↓
ESCALATE
```

The controller will never automatically scale the service beyond the configured maximum.

This prevents an abnormal condition from creating uncontrolled infrastructure growth and unexpected costs.

---

## 10. Recovery Verification

Healing is not considered successful simply because an action was executed.

After a recovery action, the controller schedules a delayed verification using EventBridge Scheduler.

```text
Failure
  ↓
Healing Action
  ↓
Cooldown
  ↓
Verification
  ↓
CloudWatch Alarm State
  │
  ├── OK → RECOVERY_CONFIRMED
  │
  └── ALARM
        ↓
      Retry
        ↓
      Escalate
```

This separates healing from verification and avoids blocking Lambda execution with `sleep()`.

---

## 11. Chaos Engineering

The platform is validated using controlled failure injection.

The main objective is to verify that the self-healing mechanism behaves correctly under realistic failure conditions.

The current chaos tests include:

### Test 1 — CPU Self-Healing

Inject high CPU utilization using:

```bash
stress-ng --cpu 4 --timeout 300s
```

Expected behavior:

```text
High CPU
   ↓
CloudWatch ALARM
   ↓
EventBridge
   ↓
Lambda
   ↓
Scale ECS
```

Observed behavior:

```text
CPU ≈ 95% average
Maximum ≈ 100%

2 tasks → 3 tasks
```

Result:

```text
PASS
```

---

### Test 2 — Maximum Scaling Safety Boundary

The service is intentionally driven through multiple scaling events:

```text
2 → 3 → 4 → 5
```

At five tasks, another high CPU condition is introduced.

Expected behavior:

```text
5 tasks
   ↓
High CPU
   ↓
MAX_TASKS_REACHED
   ↓
ESCALATE
```

The controller must not create a sixth task.

---

### Test 3 — Recovery Detection

After the failure condition is removed:

```text
ALARM
  ↓
OK
```

The self-healing controller should detect the recovered CloudWatch alarm state and log:

```text
RECOVERY_CONFIRMED
```

Complete test evidence and procedures are documented in:

`docs/chaos-testing.md`

---

## 12. Project Documentation

| Document            | Purpose                                        |
| ------------------- | ---------------------------------------------- |
| `architecture.md`   | System architecture and component interactions |
| `infrastructure.md` | Terraform and AWS infrastructure               |
| `ci-cd.md`          | GitHub Actions build/deployment pipeline       |
| `monitoring.md`     | CloudWatch metrics, alarms and logs            |
| `self-healing.md`   | Autonomous recovery mechanism                  |
| `chaos-testing.md`  | Failure injection and validation               |

---

## 13. Design Principles

The platform was designed around several principles:

### Automation

Infrastructure recovery should require minimal manual intervention.

### Observability

The system must detect and understand abnormal behavior before attempting recovery.

### Controlled Recovery

Recovery actions must be bounded and deterministic.

### Verification

A recovery action must be followed by verification.

### Idempotency

Repeated events should not result in uncontrolled infrastructure changes.

### Safety

The system must have explicit scaling and retry limits.

### Cost Awareness

The infrastructure is designed to remain suitable for development and academic experimentation.

---

## 14. Project Status

Current implementation includes:

- [x] Terraform infrastructure
- [x] Modular AWS architecture
- [x] Dockerized application
- [x] ECS Fargate deployment
- [x] ECR
- [x] Application Load Balancer
- [x] RDS PostgreSQL
- [x] Secrets Manager
- [x] GitHub Actions CI
- [x] GitHub Actions CD
- [x] CloudWatch metrics
- [x] CloudWatch alarms
- [x] EventBridge event routing
- [x] Self-healing Lambda
- [x] EventBridge Scheduler verification
- [x] ECS controlled scaling
- [x] Recovery detection
- [x] Chaos testing
- [x] Safety boundary testing

---

## 15. Future Improvements

Potential future improvements include:

- GitHub Actions OIDC instead of long-lived AWS credentials
- HTTPS with ACM and Route 53
- More sophisticated anomaly detection
- Distributed tracing
- Advanced application-level health checks
- Persistent incident history
- Multi-service healing policies
- Kubernetes-based deployment
- Advanced observability using OpenTelemetry

---

## 16. Author

**Rami Ghazzawi**

Computer Science Student
An-Najah National University

Focus:

```text
Cloud Engineering
DevOps
Cloud Infrastructure
Automation
Self-Healing Systems
```
