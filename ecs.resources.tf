data "aws_region" "current" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.ecs.cluster_name}-cluster-${var.env}"
}

resource "aws_ecs_task_definition" "task" {
  for_each                 = { for task in var.ecs.tasks : task.name => task }
  family                   = "${each.key}-service-${var.env}"
  network_mode             = each.value.network_mode
  requires_compatibilities = each.value.requires_compatibilities
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = lookup(var.roles, each.value.execution_role)
  task_role_arn            = lookup(var.roles, each.value.task_role)
  container_definitions = jsonencode(
    [for definition in concat([for definition in each.value.container_definitions :
      merge(definition, {
        name      = definition.name != null ? definition.name : "${each.key}-service-${var.env}",
        image     = definition.image != null ? definition.image : "${aws_ecr_repository.ecr.repository_url}:${each.key}",
        dependsOn = var.mesh != null ? [{ containerName = var.mesh.sidecar_proxy.name, condition = "HEALTHY" }] : []
      })
      ],
      var.mesh != null ? [
        merge(
          var.mesh.sidecar_proxy,
          { environment = concat(var.mesh.sidecar_proxy.environment, [{ name = "APPMESH_RESOURCE_ARN", value = lookup(one(module.mesh[*].virtual_nodes), each.key) }]) }
      )] : []
      ) : merge(definition, { logConfiguration = { logDriver = "awslogs",
        options = { awslogs-group = "${each.key}-service-${var.env}",
          awslogs-region = data.aws_region.current.name, awslogs-stream-prefix = "ecs"
    } } })]
  )

  dynamic "proxy_configuration" {
    for_each = var.mesh != null ? [var.mesh.proxy_configuration] : []
    content {
      type           = proxy_configuration.value.type
      container_name = proxy_configuration.value.container_name
      properties = {
        AppPorts         = proxy_configuration.value.properties.AppPorts
        EgressIgnoredIPs = proxy_configuration.value.properties.EgressIgnoredIPs
        IgnoredUID       = proxy_configuration.value.properties.IgnoredUID
        ProxyEgressPort  = proxy_configuration.value.properties.ProxyEgressPort
        ProxyIngressPort = proxy_configuration.value.properties.ProxyIngressPort
      }
    }
  }
  depends_on = [
    aws_ecr_repository.ecr,
    module.mesh
  ]
}

resource "aws_ecs_service" "service" {
  for_each                           = { for service in var.ecs.services : service.name => service }
  name                               = "${each.key}-service-${var.env}"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = lookup(aws_ecs_task_definition.task, each.key).arn
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

  dynamic "service_registries" {
    for_each = var.mesh != null ? [lookup(one(module.mesh[*].service_discovery), each.key)] : []
    content {
      registry_arn = service_registries.value
    }
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    aws_ecs_task_definition.task
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
