data "aws_region" "current" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.ecs.cluster_name}-cluster-${var.env}"
}

module "consul_server" {
  source                      = "./modules/consul"
  env                         = var.env
  vpc_id                      = var.vpc_id
  cluster                     = aws_ecs_cluster.cluster.arn
  requires_compatibilities    = var.ecs.consul_server.requires_compatibilities
  cpu                         = var.ecs.consul_server.cpu
  memory                      = var.ecs.consul_server.memory
  subnets                     = [for subnet in var.ecs.consul_server.subnets : lookup(var.subnets, subnet)]
  target_group                = lookup(var.target_groups, var.ecs.consul_server.target_group)
  security_groups             = [for group in var.ecs.consul_server.security_groups : lookup(var.security_groups, group)]
  lb_enabled                  = var.ecs.consul_server.lb_enabled
  consul_image                = var.ecs.consul_server.consul_image
  consul_license              = var.ecs.consul_server.consul_license
  name                        = var.ecs.consul_server.name
  service_discovery_namespace = var.ecs.consul_server.service_discovery_namespace
  tags                        = var.ecs.consul_server.tags
  launch_type                 = var.ecs.consul_server.launch_type
  assign_public_ip            = var.ecs.consul_server.assign_public_ip
  tls                         = var.ecs.consul_server.tls
  gossip_key_secret_arn       = var.ecs.consul_server.gossip_key_secret_arn
  acls                        = var.ecs.consul_server.acls
  wait_for_steady_state       = var.ecs.consul_server.wait_for_steady_state
  depends_on = [
    aws_ecs_cluster.cluster
  ]
}

module "task" {
  for_each                 = { for task in var.ecs.tasks : task.name => task }
  source                   = "./modules/task"
  family                   = "${each.key}-service-${var.env}"
  requires_compatibilities = each.value.requires_compatibilities
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  port                     = each.value.port
  execution_role           = lookup(var.roles, each.value.execution_role)
  task_role                = lookup(var.roles, each.value.task_role)
  retry_join               = [module.consul_server.server_dns]
  log_configuration        = { logDriver = "awslogs", options = { awslogs-group = "${each.key}-service-${var.env}", awslogs-region = data.aws_region.current.name, awslogs-stream-prefix = "ecs" } }
  consul_datacenter        = each.value.consul_datacenter
  container_definitions    = [for definition in each.value.container_definitions : merge(definition, { name = "${each.key}-service-${var.env}", image = "${aws_ecr_repository.ecr.repository_url}:${each.key}", logConfiguration = { logDriver = "awslogs", options = { awslogs-group = "${each.key}-service-${var.env}", awslogs-region = data.aws_region.current.name, awslogs-stream-prefix = "ecs" } } })]
  upstreams                = each.value.upstreams
  depends_on = [
    aws_ecr_repository.ecr,
    module.consul_server
  ]
}

resource "aws_ecs_service" "service" {
  for_each                           = { for service in var.ecs.services : service.name => service }
  name                               = "${each.key}-service-${var.env}"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = lookup(module.task, each.key).task_definition_arn
  desired_count                      = each.value.desired_count
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  launch_type                        = each.value.launch_type
  scheduling_strategy                = each.value.scheduling_strategy

  network_configuration {
    security_groups  = [for group in each.value.network_configuration.security_groups : lookup(var.security_groups, group)]
    subnets          = [for subnet in each.value.network_configuration.subnets : lookup(var.subnets, subnet)]
    assign_public_ip = each.value.network_configuration.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = each.value.load_balancer
    content {
      target_group_arn = lookup(var.target_groups, load_balancer.value.target_group)
      container_name   = "${each.key}-service-${var.env}"
      container_port   = load_balancer.value.container_port
    }
  }

  enable_execute_command = true
  propagate_tags         = "TASK_DEFINITION"

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    module.task
  ]
}

resource "aws_appautoscaling_target" "target" {
  for_each           = { for service in var.ecs.services : service.name => service }
  max_capacity       = each.value.target.max_capacity
  min_capacity       = each.value.target.min_capacity
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${lookup(aws_ecs_service.service, each.key).name}"
  scalable_dimension = each.value.target.scalable_dimension
  service_namespace  = each.value.target.service_namespace
  depends_on = [
    aws_ecs_service.service
  ]
}

resource "aws_appautoscaling_policy" "policies" {
  for_each           = { for index, policy in flatten([for service in var.ecs.services : service.policies]) : tostring(index) => policy }
  name               = each.key
  policy_type        = each.value.policy_type
  resource_id        = lookup(aws_appautoscaling_target.target, each.value.target).resource_id
  scalable_dimension = lookup(aws_appautoscaling_target.target, each.value.target).scalable_dimension
  service_namespace  = lookup(aws_appautoscaling_target.target, each.value.target).service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value.predefined_metric_type
    }
    target_value = each.value.target_value
  }
  depends_on = [
    aws_appautoscaling_target.target
  ]
}

resource "aws_cloudwatch_log_group" "logs" {
  for_each          = { for service in var.ecs.services : service.name => service }
  name              = lookup(aws_ecs_service.service, each.key).name
  retention_in_days = each.value.log.retention_in_days
  depends_on = [
    aws_ecs_service.service
  ]
}
