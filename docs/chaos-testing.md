# Chaos Testing & Validation

## 1. Purpose

The purpose of chaos testing is to intentionally introduce controlled failures and verify that the Autonomous Self-Healing Cloud Platform responds according to its defined recovery and safety policies.

The tests validate:

- Failure detection
- CloudWatch alarm triggering
- EventBridge event routing
- Lambda execution
- ECS recovery actions
- Safety boundaries
- Recovery verification
- Escalation behavior

---

# 2. Test Environment

| Component             | Configuration                 |
| --------------------- | ----------------------------- |
| AWS Region            | `eu-west-2`                   |
| ECS Cluster           | `dev-ecs-cluster`             |
| ECS Service           | `dev-service`                 |
| Container             | `app`                         |
| Container Port        | `8080`                        |
| Initial Desired Count | `2`                           |
| Maximum Tasks         | `5`                           |
| CPU Alarm Threshold   | `80%`                         |
| Evaluation Periods    | `2`                           |
| Lambda                | `dev-self-healing-controller` |
| Stress Tool           | `stress-ng`                   |

---

# 3. Test 1 — CPU Self-Healing

## Objective

Verify that sustained high CPU utilization triggers the CloudWatch alarm and causes the self-healing controller to scale the ECS service.

## Failure Injection

CPU stress is introduced into the running ECS tasks using:

```bash
stress-ng --cpu 4 --timeout 300s
```

The stress test is applied across the running tasks so that service-level average CPU utilization exceeds the CloudWatch alarm threshold.

## Expected Flow

```text
CPU Stress
    ↓
High ECS CPU Utilization
    ↓
CloudWatch Alarm
    ↓
ALARM
    ↓
EventBridge
    ↓
Self-Healing Lambda
    ↓
Inspect Current Task Count
    ↓
Scale +1
    ↓
ECS Desired Count
2 → 3
```

## Observed Result

During testing, ECS CPU utilization reached approximately:

```text
Average: ~95%
Maximum: 100%
```

The CPU alarm transitioned from:

```text
OK → ALARM
```

The self-healing controller increased the desired task count:

```text
2 → 3
```

## Result

```text
PASS
```

The platform successfully detected high CPU utilization and performed the configured recovery action.

---

# 4. Test 2 — Maximum Scaling Safety Boundary

## Objective

Verify that the self-healing controller cannot scale the ECS service beyond the configured maximum task count.

Configuration:

```text
MAX_TASKS = 5
```

## Test Sequence

The service is intentionally driven through multiple CPU failure conditions.

```text
2 → 3 → 4 → 5
```

At each stage, CPU stress is introduced across the running tasks.

## Expected Behavior

When the service reaches five tasks:

```text
Current Tasks = 5
MAX_TASKS = 5
```

Another CPU alarm must not result in:

```text
5 → 6
```

Instead:

```text
MAX_TASKS_REACHED
        ↓
     ESCALATE
```

## Validation

Verify ECS desired count:

```bash
aws ecs describe-services \
  --cluster dev-ecs-cluster \
  --services dev-service \
  --query "services[0].desiredCount" \
  --output text
```

Expected:

```text
5
```

Inspect the self-healing Lambda logs:

```bash
aws logs tail /aws/lambda/dev-self-healing-controller \
  --since 15m \
  --format short
```

Or filter for safety events:

```bash
aws logs tail /aws/lambda/dev-self-healing-controller \
  --since 15m \
  --format short | grep -Ei "ESCALATE|MAX_TASKS|ERROR"
```

## Expected Result

```text
Desired Count = 5
No sixth task created
MAX_TASKS_REACHED
ESCALATE
```

## Result

```text
PASS
```

---

# 5. Test 3 — Recovery Detection

## Objective

Verify that the controller recognizes when the failure condition has been resolved.

## Procedure

After the CPU stress condition is removed, ECS CPU utilization should return below the configured alarm threshold.

CloudWatch should transition:

```text
ALARM → OK
```

The recovery event is then routed through EventBridge to the self-healing Lambda.

## Expected Log

```text
RECOVERY_CONFIRMED
```

## Validation

```bash
aws logs tail /aws/lambda/dev-self-healing-controller \
  --since 15m \
  --format short | grep -Ei "RECOVERY|CONFIRMED|OK"
```

## Expected Flow

```text
CPU Stress Ends
      ↓
CPU Returns to Normal
      ↓
CloudWatch Alarm
ALARM → OK
      ↓
EventBridge
      ↓
Lambda
      ↓
RECOVERY_CONFIRMED
```

## Result

```text
PASS
```

---

# 6. Test 4 — Retry Boundary

## Objective

Verify that repeated failure does not cause unlimited automated recovery attempts.

Configuration:

```text
MAX_RETRIES = 3
```

If the alarm remains in `ALARM` after a healing action, the controller performs another verification cycle.

```text
Failure
  ↓
Healing
  ↓
Verification
  ↓
Still ALARM
  ↓
Retry
  ↓
Verification
  ↓
Still ALARM
  ↓
Retry
  ↓
Maximum retries reached
  ↓
ESCALATE
```

The system must stop automated recovery after the configured retry limit.

---

# 7. Test 5 — Cooldown Verification

## Objective

Verify that the system does not continuously execute recovery actions without a delay.

Configuration:

```text
COOLDOWN_SECONDS = 120
```

The controller uses EventBridge Scheduler to perform delayed verification.

It does not block Lambda execution using:

```python
sleep(...)
```

Instead:

```text
Healing
  ↓
Create Scheduler Job
  ↓
Wait
  ↓
Verification Lambda Invocation
```

This improves resource efficiency and keeps Lambda execution short-lived.

---

# 8. ECS Exec Validation

ECS Exec is used during chaos testing to access running containers.

The ECS service must have ECS Exec enabled.

Verification:

```bash
aws ecs describe-services \
  --cluster dev-ecs-cluster \
  --services dev-service \
  --query "services[0].enableExecuteCommand" \
  --output text
```

Expected:

```text
True
```

The Execute Command Agent should also be running inside the task.

```bash
aws ecs describe-tasks \
  --cluster dev-ecs-cluster \
  --tasks TASK_ID \
  --query "tasks[0].containers[0].managedAgents" \
  --output table
```

Expected:

```text
ExecuteCommandAgent
RUNNING
```

---

# 9. Test Evidence

Each test should be supported by evidence rather than assumptions.

Recommended screenshots:

### Test 1

- CloudWatch CPU utilization approaching 100%
- CPU alarm changing `OK → ALARM`
- ECS desired count changing `2 → 3`
- Lambda log showing the recovery action

### Test 2

- ECS desired count reaching `5`
- CloudWatch alarm in `ALARM`
- Lambda log showing `MAX_TASKS_REACHED`
- Lambda log showing `ESCALATE`
- ECS remaining at five tasks

### Test 3

- CloudWatch alarm changing `ALARM → OK`
- Lambda log showing `RECOVERY_CONFIRMED`

### Test 4

- Lambda logs showing retry progression
- Final `ESCALATE`

### Test 5

- EventBridge Scheduler execution
- Verification occurring after the configured cooldown

---

# 10. Test Results Summary

| Test | Scenario           | Expected Behavior      | Result |
| ---- | ------------------ | ---------------------- | ------ |
| 1    | High CPU           | Scale ECS +1           | PASS   |
| 2    | Maximum task count | Stop at 5 and escalate | PASS   |
| 3    | Failure recovery   | Confirm recovery       | PASS   |
| 4    | Repeated failure   | Stop after max retries | PASS   |
| 5    | Cooldown           | Delayed verification   | PASS   |

Only mark a test as `PASS` after collecting the corresponding evidence.

---

# 11. Engineering Conclusions

The chaos tests demonstrate that the platform is not only capable of detecting failures, but can also respond to them within predefined operational boundaries.

The most important properties validated by the tests are:

```text
Detection
   +
Decision
   +
Controlled Recovery
   +
Verification
   +
Safety Boundaries
   +
Escalation
```

This transforms the project from a simple monitoring implementation into an event-driven autonomous recovery system.

---

# 12. Cost Cleanup

After completing chaos tests, return the service to its normal configuration:

```bash
aws ecs update-service \
  --cluster dev-ecs-cluster \
  --service dev-service \
  --desired-count 2
```

Verify:

```text
Desired = 2
Running = 2
Pending = 0
```

For temporary development infrastructure, Terraform resources can be destroyed after collecting the required evidence:

```bash
terraform destroy
```

This prevents unnecessary AWS charges during periods when the platform is not being actively used.
