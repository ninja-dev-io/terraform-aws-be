variable "ecs" {
  type = object({
    cluster_name                       = string
    service_name                       = string
    container_name                     = string
    family                             = string
    network_mode                       = string
    requires_compatibilities           = list(string)
    cpu                                = number
    memory                             = number
    desired_count                      = number
    deployment_minimum_healthy_percent = number
    deployment_maximum_percent         = number
    launch_type                        = string
    scheduling_strategy                = string
    execution_role                     = string
    task_role                          = string
    container_definitions = list(object({
      image     = string
      essential = bool
      portMappings = list(object({
        protocol      = string
        containerPort = number
        hostPort      = number
      }))
    }))
    network_configuration = object({
      security_groups  = list(string)
      subnets          = list(string)
      assign_public_ip = bool
    })
    load_balancer = object({
      target_group   = string
      container_name = string
      container_port = number
    })
    autoscaling = object({
      max_capacity = number
      min_capacity = number
      policies = list(object({
        name                   = string
        policy_type            = string
        predefined_metric_type = string
        target_value           = number
      }))
    })
  })
}

