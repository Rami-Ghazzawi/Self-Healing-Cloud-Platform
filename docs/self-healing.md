# Self-Healing System

## 1. Purpose

The self-healing controller transforms monitoring signals into controlled infrastructure recovery actions.

## 2. Architecture

CloudWatch
↓
EventBridge
↓
Lambda
↓
Diagnosis
↓
Healing
↓
Scheduler
↓
Verification

## 3. Lambda Responsibilities

- Receive events
- Identify alarm
- Inspect ECS
- Inspect ALB
- Select recovery action
- Apply recovery
- Schedule verification
- Retry
- Confirm recovery
- Escalate

## 4. Failure Types

### CPU

High CPU:
2 → 3 → 4 → 5

Maximum reached:
ESCALATE

### Memory

Unhealthy task:
Replace task

Healthy targets:
Scale out

### ALB 5XX

Inspect target health before taking action.

## 5. Verification

Healing is not considered successful until the alarm returns to OK.

## 6. Retry Mechanism

MAX_RETRIES = 3

Each verification carries the retry count through the EventBridge Scheduler payload.

## 7. Cooldown

COOLDOWN_SECONDS = 120

EventBridge Scheduler is used instead of blocking Lambda execution.

## 8. Safety Boundaries

MIN_TASKS = 2
MAX_TASKS = 5

The controller cannot automatically scale beyond MAX_TASKS.

## 9. Escalation

When automated healing reaches its safety limit:

ESCALATE

This indicates that the system requires further investigation rather than continuing automated changes.

## 10. Recovery States

RECOVERY_CONFIRMED
WAIT
ESCALATE

## 11. Design Considerations

The system deliberately avoids blind restarts.

Recovery decisions are based on infrastructure state and health signals.
