variable "ecs" {
  type = object({
    cluster_name = string
    tasks = list(object({
      name                     = string
      essential                = bool
      network_mode             = string
      requires_compatibilities = list(string)
      cpu                      = number
      memory                   = number
      execution_role           = string
      task_role                = string
      container_definitions = list(object({
        essential = bool
        healthCheck = object({
          command  = list(string)
          interval = number
          retries  = number
          timeout  = number
        })
        portMappings = list(object({
          protocol      = string
          containerPort = number
          hostPort      = number
        }))
        environment = list(object({
          name  = string
          value = string
        }))
      }))
    }))
    services = list(object({
      name                               = string
      family                             = string
      port                               = number
      desired_count                      = number
      deployment_minimum_healthy_percent = number
      deployment_maximum_percent         = number
      launch_type                        = string
      scheduling_strategy                = string
      network_configuration = object({
        security_groups  = list(string)
        subnets          = list(string)
        assign_public_ip = bool
      })
      load_balancer = list(object({
        target_group   = string
        container_name = string
        container_port = number
      }))
      target = object({
        max_capacity       = number
        min_capacity       = number
        scalable_dimension = string
        service_namespace  = string
      })
      policies = list(object({
        name                   = string
        target                 = string
        policy_type            = string
        target                 = string
        predefined_metric_type = string
        target_value           = number
      }))
      log = object({
        retention_in_days = string
      })
      backend = list(string)
    }))
  })
}

