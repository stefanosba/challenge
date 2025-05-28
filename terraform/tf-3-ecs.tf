resource "aws_ecs_cluster" "ecs" {
  name = "${local.app_name}-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "reverse-proxy"
      image = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.reverse_proxy.name}:latest"
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.app_name}-reverse-proxy"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "reverse-proxy"
        }
      }
    },
    {
      name      = "rest-api"
      image = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.rest_api.name}:latest"
      essential = false
      portMappings = [{
        containerPort = 8000
        hostPort      = 8000
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.app_name}-rest-api"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "rest-api"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "app" {
  name            = "${local.app_name}-service"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.reverse_proxy_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.reverse_proxy.arn
    container_name   = "reverse-proxy"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_target_group.reverse_proxy
  ] 
}

resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.app]
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "${local.app_name}-cpu-scaling-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0 
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300 
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "memory_policy" {
  name               = "${local.app_name}-memory-scaling-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = 75.0 
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}