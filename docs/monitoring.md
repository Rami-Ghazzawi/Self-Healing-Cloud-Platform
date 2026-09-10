# Monitoring & Observability

## 1. Monitoring Architecture

Application
↓
ECS / ALB
↓
CloudWatch
↓
Metrics + Logs
↓
Alarms
↓
EventBridge

## 2. ECS Metrics

### CPUUtilization

### MemoryUtilization

### LiveTaskCount

## 3. ALB Metrics

### HTTPCode_Target_5XX_Count

### Target Health

## 4. CloudWatch Alarms

### CPU Alarm

Threshold: 80%
Evaluation: 2 periods
Statistic: Average

### ALB 5XX Alarm

## 5. Logs

/aws/lambda/dev-self-healing-controller
/ecs/dev-app

## 6. Alarm State Lifecycle

OK → ALARM → OK

## 7. Monitoring vs Self-Healing

Monitoring detects the problem.

Self-Healing responds to the problem.
