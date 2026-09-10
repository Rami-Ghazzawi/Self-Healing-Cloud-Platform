# ============================================================
# CPU - ALARM
# ============================================================

resource "aws_cloudwatch_event_rule" "cpu_alarm" {
  name = "${var.environment}-cpu-alarm"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]

    detail-type = [
      "CloudWatch Alarm State Change"
    ]

    detail = {
      alarmName = [
        "${var.environment}-ecs-cpu-utilization-high"
      ]

      state = {
        value = [
          "ALARM"
        ]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "cpu_alarm" {
  rule = aws_cloudwatch_event_rule.cpu_alarm.name

  arn = aws_lambda_function.self_healing.arn
}


resource "aws_lambda_permission" "cpu_alarm" {
  statement_id = "AllowCPUAlarmEventBridge"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.self_healing.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.cpu_alarm.arn
}


# ============================================================
# CPU - RECOVERY
# ============================================================

resource "aws_cloudwatch_event_rule" "cpu_recovery" {
  name = "${var.environment}-cpu-recovery"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]

    detail-type = [
      "CloudWatch Alarm State Change"
    ]

    detail = {
      alarmName = [
        "${var.environment}-ecs-cpu-utilization-high"
      ]

      state = {
        value = [
          "OK"
        ]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "cpu_recovery" {
  rule = aws_cloudwatch_event_rule.cpu_recovery.name

  arn = aws_lambda_function.self_healing.arn
}


resource "aws_lambda_permission" "cpu_recovery" {
  statement_id = "AllowCPURecoveryEventBridge"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.self_healing.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.cpu_recovery.arn
}


# ============================================================
# MEMORY - ALARM
# ============================================================

resource "aws_cloudwatch_event_rule" "memory_alarm" {
  name = "${var.environment}-memory-alarm"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]

    detail-type = [
      "CloudWatch Alarm State Change"
    ]

    detail = {
      alarmName = [
        "${var.environment}-ecs-memory-utilization-high"
      ]

      state = {
        value = [
          "ALARM"
        ]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "memory_alarm" {
  rule = aws_cloudwatch_event_rule.memory_alarm.name

  arn = aws_lambda_function.self_healing.arn
}


resource "aws_lambda_permission" "memory_alarm" {
  statement_id = "AllowMemoryAlarmEventBridge"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.self_healing.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.memory_alarm.arn
}


# ============================================================
# MEMORY - RECOVERY
# ============================================================

resource "aws_cloudwatch_event_rule" "memory_recovery" {
  name = "${var.environment}-memory-recovery"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]

    detail-type = [
      "CloudWatch Alarm State Change"
    ]

    detail = {
      alarmName = [
        "${var.environment}-ecs-memory-utilization-high"
      ]

      state = {
        value = [
          "OK"
        ]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "memory_recovery" {
  rule = aws_cloudwatch_event_rule.memory_recovery.name

  arn = aws_lambda_function.self_healing.arn
}


resource "aws_lambda_permission" "memory_recovery" {
  statement_id = "AllowMemoryRecoveryEventBridge"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.self_healing.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.memory_recovery.arn
}


# ============================================================
# ALB 5XX - ALARM
# ============================================================

resource "aws_cloudwatch_event_rule" "alb_5xx_alarm" {
  name = "${var.environment}-alb-5xx-alarm"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]

    detail-type = [
      "CloudWatch Alarm State Change"
    ]

    detail = {
      alarmName = [
        "${var.environment}-alb-5xx-errors"
      ]

      state = {
        value = [
          "ALARM"
        ]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "alb_5xx_alarm" {
  rule = aws_cloudwatch_event_rule.alb_5xx_alarm.name

  arn = aws_lambda_function.self_healing.arn
}


resource "aws_lambda_permission" "alb_5xx_alarm" {
  statement_id = "AllowALB5xxAlarmEventBridge"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.self_healing.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.alb_5xx_alarm.arn
}


# ============================================================
# ALB 5XX - RECOVERY
# ============================================================

resource "aws_cloudwatch_event_rule" "alb_5xx_recovery" {
  name = "${var.environment}-alb-5xx-recovery"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]

    detail-type = [
      "CloudWatch Alarm State Change"
    ]

    detail = {
      alarmName = [
        "${var.environment}-alb-5xx-errors"
      ]

      state = {
        value = [
          "OK"
        ]
      }
    }
  })
}


resource "aws_cloudwatch_event_target" "alb_5xx_recovery" {
  rule = aws_cloudwatch_event_rule.alb_5xx_recovery.name

  arn = aws_lambda_function.self_healing.arn
}


resource "aws_lambda_permission" "alb_5xx_recovery" {
  statement_id = "AllowALB5xxRecoveryEventBridge"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.self_healing.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.alb_5xx_recovery.arn
}