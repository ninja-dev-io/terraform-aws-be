variable "ecs" {
  type = object({
    cluster_name = string
    consul_server = object({
      requires_compatibilities    = list(string)
      cpu                         = number
      memory                      = number
      subnets                     = list(string)
      target_group                = string
      security_groups             = list(string)
      lb_enabled                  = bool
      consul_image                = string
      consul_license              = string
      name                        = string
      service_discovery_namespace = string
      tags                        = map(string)
      launch_type                 = string
      assign_public_ip            = bool
      tls                         = bool
      gossip_key_secret_arn       = string
      acls                        = bool
      wait_for_steady_state       = bool
    })
    tasks = list(object({
      name                     = string
      essential                = bool
      requires_compatibilities = list(string)
      cpu                      = number
      memory                   = number
      port                     = number
      execution_role           = string
      task_role                = string
      consul_datacenter        = string
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
      upstreams = list(object({
        destinationName = string
        localBindPort   = number
      }))
    }))
    services = list(object({
      name                               = string
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
    }))
  })
}

