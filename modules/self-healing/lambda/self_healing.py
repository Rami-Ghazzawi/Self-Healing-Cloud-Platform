import os
import json
import uuid
import boto3
import logging
from datetime import datetime, timedelta, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# ============================================================
# AWS clients
# ============================================================

ecs = boto3.client("ecs")
elbv2 = boto3.client("elbv2")
cloudwatch = boto3.client("cloudwatch")
scheduler = boto3.client("scheduler")


# ============================================================
# Configuration
# ============================================================

ECS_CLUSTER = os.environ["ECS_CLUSTER"]
ECS_SERVICE = os.environ["ECS_SERVICE"]
TARGET_GROUP_ARN = os.environ["TARGET_GROUP_ARN"]

SCHEDULER_ROLE_ARN = os.environ["SCHEDULER_ROLE_ARN"]

MIN_TASKS = int(os.environ.get("MIN_TASKS", "2"))
MAX_TASKS = int(os.environ.get("MAX_TASKS", "5"))

CPU_SCALE_INCREMENT = int(
    os.environ.get("CPU_SCALE_INCREMENT", "1")
)

MAX_RETRIES = int(
    os.environ.get("MAX_RETRIES", "3")
)

COOLDOWN_SECONDS = int(
    os.environ.get("COOLDOWN_SECONDS", "120")
)


# ============================================================
# Event helpers
# ============================================================

def get_alarm_name(event):
    return (
        event
        .get("detail", {})
        .get("alarmName")
    )


def get_alarm_state(event):
    return (
        event
        .get("detail", {})
        .get("state", {})
        .get("value")
    )


# ============================================================
# ECS state
# ============================================================

def get_service_state():
    response = ecs.describe_services(
        cluster=ECS_CLUSTER,
        services=[ECS_SERVICE]
    )

    services = response.get("services", [])

    if not services:
        raise RuntimeError(
            f"ECS service not found: {ECS_SERVICE}"
        )

    service = services[0]

    return {
        "desired": service.get("desiredCount", 0),
        "running": service.get("runningCount", 0),
        "pending": service.get("pendingCount", 0),
    }


def get_running_tasks():
    response = ecs.list_tasks(
        cluster=ECS_CLUSTER,
        serviceName=ECS_SERVICE,
        desiredStatus="RUNNING"
    )

    return response.get("taskArns", [])


def get_task_details(task_arns):
    if not task_arns:
        return []

    response = ecs.describe_tasks(
        cluster=ECS_CLUSTER,
        tasks=task_arns
    )

    return response.get("tasks", [])


# ============================================================
# ALB target health
# ============================================================

def get_target_health():
    response = elbv2.describe_target_health(
        TargetGroupArn=TARGET_GROUP_ARN
    )

    return response.get(
        "TargetHealthDescriptions",
        []
    )


def get_unhealthy_targets():
    targets = get_target_health()

    unhealthy = []

    for target in targets:
        target_health = target.get(
            "TargetHealth",
            {}
        )

        state = target_health.get("State")

        if state != "healthy":
            unhealthy.append({
                "target": target.get("Target", {}),
                "state": state,
                "reason": target_health.get("Reason"),
                "description": target_health.get(
                    "Description"
                )
            })

    return unhealthy


# ============================================================
# CloudWatch alarm state
# ============================================================

def get_current_alarm_state(alarm_name):

    response = cloudwatch.describe_alarms(
        AlarmNames=[alarm_name]
    )

    alarms = response.get(
        "MetricAlarms",
        []
    )

    if not alarms:
        raise RuntimeError(
            f"CloudWatch alarm not found: {alarm_name}"
        )

    return alarms[0].get("StateValue")


# ============================================================
# Safety boundaries
# ============================================================

def can_scale_out(service_state):

    desired = service_state["desired"]

    if desired >= MAX_TASKS:

        logger.warning(
            "Scale-out blocked. "
            "desired=%s max=%s",
            desired,
            MAX_TASKS
        )

        return False

    return True


def calculate_new_desired_count(
    current_desired
):

    new_desired = (
        current_desired +
        CPU_SCALE_INCREMENT
    )

    return min(
        new_desired,
        MAX_TASKS
    )


# ============================================================
# Healing actions
# ============================================================

def scale_out(service_state):

    current_desired = service_state["desired"]
    running = service_state["running"]
    pending = service_state["pending"]

    # --------------------------------------------------------
    # Boundary
    # --------------------------------------------------------

    if current_desired >= MAX_TASKS:

        return {
            "action": "ESCALATE",
            "reason": "MAX_TASKS_REACHED",
            "desired": current_desired,
            "max_tasks": MAX_TASKS
        }

    # --------------------------------------------------------
    # Prevent duplicate scale-out while ECS is already
    # starting another task.
    # --------------------------------------------------------

    if pending > 0:

        logger.info(
            "Scale-out skipped. "
            "ECS already has pending tasks."
        )

        return {
            "action": "WAIT",
            "reason": "TASKS_ALREADY_PENDING",
            "desired": current_desired,
            "running": running,
            "pending": pending
        }

    # --------------------------------------------------------
    # Scale out
    # --------------------------------------------------------

    new_desired = calculate_new_desired_count(
        current_desired
    )

    logger.warning(
        "Scaling ECS service %s -> %s",
        current_desired,
        new_desired
    )

    ecs.update_service(
        cluster=ECS_CLUSTER,
        service=ECS_SERVICE,
        desiredCount=new_desired
    )

    return {
        "action": "SCALE_OUT",
        "from": current_desired,
        "to": new_desired
    }


def replace_unhealthy_task(task_arn):

    logger.warning(
        "Replacing unhealthy task: %s",
        task_arn
    )

    ecs.stop_task(
        cluster=ECS_CLUSTER,
        task=task_arn,
        reason=(
            "Self-healing: "
            "unhealthy task replacement"
        )
    )

    return {
        "action": "REPLACE_TASK",
        "task": task_arn
    }


# ============================================================
# CPU healing
# ============================================================

def handle_cpu_alarm(service_state):

    logger.warning(
        "CPU alarm detected."
    )

    return scale_out(
        service_state
    )


# ============================================================
# Memory healing
# ============================================================

def handle_memory_alarm(service_state):

    logger.warning(
        "Memory alarm detected."
    )

    unhealthy_targets = (
        get_unhealthy_targets()
    )

    if unhealthy_targets:

        logger.warning(
            "Unhealthy ALB targets detected: %s",
            unhealthy_targets
        )

        task_arns = get_running_tasks()
        tasks = get_task_details(task_arns)

        for task in tasks:

            if task.get("healthStatus") == "UNHEALTHY":

                return replace_unhealthy_task(
                    task["taskArn"]
                )

    # Healthy tasks + high memory:
    # scale instead of killing healthy infrastructure.

    return scale_out(
        service_state
    )


# ============================================================
# ALB 5xx healing
# ============================================================

def handle_5xx_alarm(service_state):

    logger.warning(
        "ALB 5xx alarm detected."
    )

    unhealthy_targets = (
        get_unhealthy_targets()
    )

    if unhealthy_targets:

        logger.warning(
            "Unhealthy ALB targets: %s",
            unhealthy_targets
        )

        task_arns = get_running_tasks()
        tasks = get_task_details(task_arns)

        for task in tasks:

            if task.get("healthStatus") == "UNHEALTHY":

                return replace_unhealthy_task(
                    task["taskArn"]
                )

        return {
            "action": "ESCALATE",
            "reason": (
                "ALB_UNHEALTHY_TARGETS_BUT_"
                "NO_UNHEALTHY_ECS_TASK"
            )
        }

    return {
        "action": "ESCALATE",
        "reason": "5XX_WITH_HEALTHY_TARGETS"
    }


# ============================================================
# Healing dispatcher
# ============================================================

def execute_healing(
    alarm_name,
    service_state
):

    if alarm_name == "dev-ecs-cpu-utilization-high":

        return handle_cpu_alarm(
            service_state
        )

    if alarm_name == "dev-ecs-memory-utilization-high":

        return handle_memory_alarm(
            service_state
        )

    if alarm_name == "dev-alb-5xx-errors":

        return handle_5xx_alarm(
            service_state
        )

    return {
        "action": "IGNORE",
        "reason": f"Unknown alarm: {alarm_name}"
    }


# ============================================================
# Cooldown / Retry Scheduler
# ============================================================

def schedule_verification(
    alarm_name,
    retry_count,
    lambda_arn
):

    # --------------------------------------------------------
    # Cooldown period
    # --------------------------------------------------------

    execution_time = (
        datetime.now(timezone.utc)
        + timedelta(
            seconds=COOLDOWN_SECONDS
        )
    )

    schedule_time = (
        execution_time
        .replace(microsecond=0)
        .strftime(
            "%Y-%m-%dT%H:%M:%S"
        )
    )

    # --------------------------------------------------------
    # Unique schedule name
    # --------------------------------------------------------

    short_alarm_name = (
        alarm_name
        .replace("_", "-")
        .replace(":", "-")
    )

    schedule_name = (
        f"self-heal-{short_alarm_name}-"
        f"r{retry_count}-"
        f"{uuid.uuid4().hex[:8]}"
    )

    # Scheduler names have a length limit.
    schedule_name = schedule_name[:64]

    payload = {
        "source": "self-healing-scheduler",
        "mode": "VERIFY",
        "alarmName": alarm_name,
        "retryCount": retry_count
    }

    logger.info(
        "Scheduling verification: "
        "alarm=%s retry=%s at=%s",
        alarm_name,
        retry_count,
        schedule_time
    )

    scheduler.create_schedule(
        Name=schedule_name,

        ScheduleExpression=(
            f"at({schedule_time})"
        ),

        FlexibleTimeWindow={
            "Mode": "OFF"
        },

        ActionAfterCompletion="DELETE",

        Target={
            "Arn": lambda_arn,
            "RoleArn": SCHEDULER_ROLE_ARN,
            "Input": json.dumps(payload)
        }
    )

    return {
        "action": "VERIFICATION_SCHEDULED",
        "alarm": alarm_name,
        "retry": retry_count,
        "scheduled_at": schedule_time,
        "cooldown_seconds": COOLDOWN_SECONDS
    }


# ============================================================
# Verification
# ============================================================

def verify_and_retry(
    alarm_name,
    retry_count,
    lambda_arn
):

    logger.info(
        "Verification started. "
        "alarm=%s retry=%s",
        alarm_name,
        retry_count
    )

    current_state = (
        get_current_alarm_state(
            alarm_name
        )
    )

    logger.info(
        "Current alarm state: %s",
        current_state
    )

    # --------------------------------------------------------
    # Recovery
    # --------------------------------------------------------

    if current_state == "OK":

        logger.info(
            "Recovery confirmed: %s",
            alarm_name
        )

        return {
            "action": "RECOVERY_CONFIRMED",
            "alarm": alarm_name,
            "retry": retry_count
        }

    # --------------------------------------------------------
    # Still unhealthy
    # --------------------------------------------------------

    if current_state != "ALARM":

        return {
            "action": "WAIT",
            "reason": (
                f"Alarm state is {current_state}"
            )
        }

    # --------------------------------------------------------
    # Retry boundary
    # --------------------------------------------------------

    if retry_count >= MAX_RETRIES:

        logger.error(
            "Maximum retries reached. "
            "Escalating alarm=%s",
            alarm_name
        )

        return {
            "action": "ESCALATE",
            "reason": "MAX_RETRIES_REACHED",
            "alarm": alarm_name,
            "retries": retry_count
        }

    # --------------------------------------------------------
    # Current infrastructure state
    # --------------------------------------------------------

    service_state = get_service_state()

    # --------------------------------------------------------
    # Execute another bounded healing action
    # --------------------------------------------------------

    result = execute_healing(
        alarm_name,
        service_state
    )

    logger.warning(
        "Retry healing result: %s",
        result
    )

    # --------------------------------------------------------
    # If action itself escalated, don't schedule another retry
    # --------------------------------------------------------

    if result.get("action") == "ESCALATE":

        return result

    # --------------------------------------------------------
    # Schedule next verification
    # --------------------------------------------------------

    next_retry = retry_count + 1

    verification = schedule_verification(
        alarm_name,
        next_retry,
        lambda_arn
    )

    return {
        "action": "RETRY_EXECUTED",
        "retry": next_retry,
        "healing": result,
        "verification": verification
    }


# ============================================================
# Recovery event
# ============================================================

def handle_recovery(
    alarm_name
):

    logger.info(
        "CloudWatch recovery event received: %s",
        alarm_name
    )

    service_state = get_service_state()

    return {
        "action": "RECOVERY_CONFIRMED",
        "alarm": alarm_name,
        "service_state": service_state
    }


# ============================================================
# Lambda handler
# ============================================================

def lambda_handler(
    event,
    context
):

    logger.info(
        "Received event: %s",
        json.dumps(event)
    )

    try:

        # ====================================================
        # Scheduled verification
        # ====================================================

        if event.get("mode") == "VERIFY":

            alarm_name = event["alarmName"]
            retry_count = int(
                event.get(
                    "retryCount",
                    0
                )
            )

            return verify_and_retry(
                alarm_name,
                retry_count,
                context.invoked_function_arn
            )

        # ====================================================
        # Normal EventBridge CloudWatch event
        # ====================================================

        alarm_name = get_alarm_name(
            event
        )

        alarm_state = get_alarm_state(
            event
        )

        if not alarm_name:
            raise ValueError(
                "Alarm name missing from event."
            )

        if not alarm_state:
            raise ValueError(
                "Alarm state missing from event."
            )

        logger.info(
            "Processing alarm=%s state=%s",
            alarm_name,
            alarm_state
        )

        # ====================================================
        # Recovery
        # ====================================================

        if alarm_state == "OK":

            result = handle_recovery(
                alarm_name
            )

            logger.info(
                "Recovery result: %s",
                result
            )

            return result

        # ====================================================
        # Ignore unsupported states
        # ====================================================

        if alarm_state != "ALARM":

            return {
                "action": "IGNORE",
                "reason": (
                    f"Unsupported alarm state: "
                    f"{alarm_state}"
                )
            }

        # ====================================================
        # Get current state before healing
        # ====================================================

        service_state = get_service_state()

        logger.info(
            "Current ECS service state: %s",
            service_state
        )

        # ====================================================
        # Initial healing
        # ====================================================

        result = execute_healing(
            alarm_name,
            service_state
        )

        logger.warning(
            "Initial healing result: %s",
            result
        )

        # ====================================================
        # Nothing to retry if escalation happened
        # ====================================================

        if result.get("action") in (
            "ESCALATE",
            "IGNORE",
            "WAIT"
        ):

            return {
                "alarm": alarm_name,
                "state": alarm_state,
                "result": result
            }

        # ====================================================
        # Schedule verification after cooldown
        # ====================================================

        verification = schedule_verification(
            alarm_name,
            retry_count=1,
            lambda_arn=context.invoked_function_arn
        )

        return {
            "alarm": alarm_name,
            "state": alarm_state,
            "healing": result,
            "verification": verification
        }

    except Exception as error:

        logger.exception(
            "Self-healing controller failed."
        )

        return {
            "statusCode": 500,
            "error": str(error)
        }