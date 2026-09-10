# System Architecture

## 1. Purpose

This document describes the architecture of the Autonomous Self-Healing Cloud Platform and explains how its infrastructure, application, monitoring, and automation components interact.

The architecture is designed around an event-driven self-healing model.

---

# 2. Architecture Overview

```text
                         ┌─────────────────┐
                         │     Internet    │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │      ALB        │
                         │ Health Checks   │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
             ┌─────────────┐             ┌─────────────┐
             │ ECS Task 1  │             │ ECS Task 2  │
             │ Node/Express│             │ Node/Express│
             └──────┬──────┘             └──────┬──────┘
                    │                           │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ RDS PostgreSQL  │
                         └─────────────────┘

                     Observability Layer
                              │
             ┌────────────────┼────────────────┐
             ▼                ▼                ▼
       ┌───────────┐    ┌───────────┐    ┌───────────┐
       │ CloudWatch│    │ CloudWatch│    │    ALB    │
       │ Metrics   │    │   Logs    │    │ Metrics   │
       └─────┬─────┘    └───────────┘    └─────┬─────┘
             │                                  │
             └────────────────┬─────────────────┘
                              ▼
                     ┌─────────────────┐
                     │ CloudWatch      │
                     │ Alarms          │
                     └────────┬────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  EventBridge    │
                     └────────┬────────┘
                              │
                              ▼
                  ┌────────────────────────┐
                  │ Self-Healing Lambda    │
                  └───────────┬────────────┘
                              │
               ┌──────────────┼──────────────┐
               ▼              ▼              ▼
             ECS             ALB         Scheduler
               │
               ▼
          Recovery
```

---

# 3. Application Layer

The application is a Node.js/Express task-management API.

The container exposes port `8080`.

The primary health endpoint is:

```text
GET /health
```

The ALB uses this endpoint to determine whether ECS targets are healthy.

Application API:

```text
GET /api/tasks
```

The application is intentionally simple because the main objective of the project is cloud infrastructure automation rather than application development.

---

# 4. Container Layer

The application is packaged as a Docker image.

```text
Dockerfile
    ↓
Docker Build
    ↓
ECR Repository
    ↓
ECS Fargate
```

The image also contains `stress-ng`, which is used exclusively for controlled chaos testing.

---

# 5. Compute Layer

Amazon ECS Fargate provides serverless container execution.

The service uses:

```text
Cluster: dev-ecs-cluster
Service: dev-service
Container: app
Port: 8080
Desired Tasks: 2
Maximum Tasks: 5
```

Fargate removes the need to manage EC2 hosts while still providing container orchestration and service-level scaling.

---

# 6. Load Balancing

An Application Load Balancer distributes incoming requests between healthy ECS tasks.

The ALB also performs health checks against:

```text
/health
```

This creates an important distinction between:

```text
Application health
        ≠
Container existence
```

A running container is not automatically considered healthy.

The ALB therefore provides an additional health signal that can be used by the self-healing controller.

---

# 7. Database Layer

The application uses Amazon RDS PostgreSQL.

The database is deployed separately from the application containers.

Database credentials are stored in AWS Secrets Manager rather than being hardcoded into the application or Terraform configuration.

---

# 8. Observability Layer

CloudWatch collects operational signals from the platform.

Primary signals include:

```text
ECS CPU Utilization
ECS Memory Utilization
Live Task Count
ALB HTTP 5XX Errors
Application Logs
```

These signals provide the inputs required by the self-healing system.

---

# 9. Event-Driven Automation

The self-healing system is intentionally event-driven.

Instead of continuously polling infrastructure, CloudWatch alarms generate events.

```text
Metric
  ↓
Alarm
  ↓
EventBridge
  ↓
Lambda
```

This reduces unnecessary execution and creates a clear separation between observation and remediation.

---

# 10. Self-Healing Controller

The Lambda function acts as the decision-making layer.

Its responsibilities include:

1. Receive an alarm event.
2. Determine the failure type.
3. Inspect the current infrastructure state.
4. Select a safe recovery action.
5. Execute the recovery action.
6. Schedule verification.
7. Retry if necessary.
8. Confirm recovery.
9. Escalate when limits are reached.

The controller does not perform blind recovery.

---

# 11. Recovery Decision Model

### CPU Alarm

```text
CPU High
   │
   ▼
Current tasks < MAX_TASKS?
   │
   ├── Yes → Scale +1
   │
   └── No → ESCALATE
```

### Memory Alarm

```text
Memory High
      │
      ▼
Is an unhealthy task/target detected?
      │
 ┌────┴────┐
 │         │
Yes        No
 │         │
 ▼         ▼
Replace   Scale Out
Task
```

### ALB 5XX Alarm

```text
ALB 5XX
   │
   ▼
Inspect target health
   │
 ┌─┴───────────────┐
 │                 │
Unhealthy        Healthy
 │                 │
 ▼                 ▼
Inspect ECS       ESCALATE
 │
 ▼
Replace unhealthy task
```

This avoids restarting healthy infrastructure when the actual problem may be application-level or external.

---

# 12. Verification Architecture

Recovery is asynchronous.

After a healing action, the Lambda creates an EventBridge Scheduler job.

```text
Healing Action
      ↓
Create Scheduler Job
      ↓
Cooldown
      ↓
Invoke Lambda
      ↓
VERIFY mode
      ↓
Check CloudWatch Alarm
```

Possible outcomes:

```text
OK
 ↓
RECOVERY_CONFIRMED

ALARM
 ↓
Retry
 ↓
Healing
 ↓
Verification

Maximum retries reached
 ↓
ESCALATE
```

The Lambda does not use blocking sleep operations.

---

# 13. Safety Architecture

The system enforces several safety boundaries:

```text
MIN_TASKS = 2
MAX_TASKS = 5
SCALE_INCREMENT = 1
MAX_RETRIES = 3
COOLDOWN = 120 seconds
```

These limits prevent the automation from becoming an uncontrolled feedback loop.

---

# 14. Failure Handling Philosophy

The system follows:

```text
Observe
  ↓
Understand
  ↓
Act
  ↓
Verify
```

rather than:

```text
Alarm
  ↓
Restart Everything
```

This distinction is central to the project's design.

---

# 15. Security

The architecture uses IAM roles for AWS service access.

Separate permissions are used for:

- ECS task execution
- ECS task runtime
- Self-healing Lambda
- EventBridge Scheduler

The Lambda receives only the permissions required to inspect and modify the relevant infrastructure.

Database credentials are managed through Secrets Manager.

---

# 16. Infrastructure as Code

All major AWS infrastructure is provisioned through Terraform.

This provides:

- Reproducibility
- Version control
- Reviewable infrastructure changes
- Modular infrastructure
- Easier environment recreation

The architecture can therefore be destroyed and recreated without manually rebuilding AWS resources.
