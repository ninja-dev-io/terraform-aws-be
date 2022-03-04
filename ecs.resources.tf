data "aws_region" "current" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.ecs.cluster_name}-cluster-${var.env}"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.ecs.family}-service-${var.env}"
  network_mode             = var.ecs.network_mode
  requires_compatibilities = var.ecs.requires_compatibilities
  cpu                      = var.ecs.cpu
  memory                   = var.ecs.memory
  execution_role_arn       = lookup(var.roles, var.ecs.execution_role)
  task_role_arn            = lookup(var.roles, var.ecs.task_role)
  container_definitions    = jsonencode([for definition in var.ecs.container_definitions : merge(definition, { name = "${var.ecs.container_name}-service-${var.env}", image = "${aws_ecr_repository.ecr.repository_url}:latest", logConfiguration = { logDriver = "awslogs", options = { awslogs-group = "${var.ecs.service_name}-service-${var.env}", awslogs-region = data.aws_region.current.name, awslogs-stream-prefix = "ecs" } } })])
  depends_on = [
    aws_ecr_repository.ecr,
    aws_cloudwatch_log_group.logs
  ]
}

resource "aws_ecs_service" "service" {
  name                               = "${var.ecs.service_name}-service-${var.env}"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.task.arn
  desired_count                      = var.ecs.desired_count
  deployment_minimum_healthy_percent = var.ecs.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.ecs.deployment_maximum_percent
  launch_type                        = var.ecs.launch_type
  scheduling_strategy                = var.ecs.scheduling_strategy

  network_configuration {
    security_groups  = [for group in var.ecs.network_configuration.security_groups : lookup(var.security_groups, group)]
    subnets          = [for subnet in var.ecs.network_configuration.subnets : lookup(var.subnets, subnet)]
    assign_public_ip = var.ecs.network_configuration.assign_public_ip
  }

  load_balancer {
    target_group_arn = lookup(var.target_groups, var.ecs.load_balancer.target_group)
    container_name   = "${var.ecs.container_name}-service-${var.env}"
    container_port   = var.ecs.load_balancer.container_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_appautoscaling_target" "target" {
  max_capacity       = var.ecs.autoscaling.max_capacity
  min_capacity       = var.ecs.autoscaling.min_capacity
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "policies" {
  for_each           = { for policy in var.ecs.autoscaling.policies : policy.name => policy }
  name               = each.key
  policy_type        = each.value.policy_type
  resource_id        = aws_appautoscaling_target.target.resource_id
  scalable_dimension = aws_appautoscaling_target.target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value.predefined_metric_type
    }

    target_value = each.value.target_value
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "${var.ecs.service_name}-service-${var.env}"
  retention_in_days = "30"
}
