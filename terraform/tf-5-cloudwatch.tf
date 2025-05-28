resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.app_name}-high-cpu-reverse-proxy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors high CPU usage"
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs.name
    ServiceName = aws_ecs_service.app.name
  }
}

resource "aws_cloudwatch_log_group" "rest_api" {
  name              = "/ecs/${local.app_name}-rest-api"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "reverse_proxy" {
  name              = "/ecs/${local.app_name}-reverse-proxy"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 7
}