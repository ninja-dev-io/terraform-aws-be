variable "mesh" {
  description = "AWS mesh configuration"
  type = object({
    name      = string
    namespace = string
    proxy_configuration = object({
      type           = string
      container_name = string
      properties = object({
        AppPorts         = string
        EgressIgnoredIPs = string
        IgnoredUID       = string
        ProxyEgressPort  = number
        ProxyIngressPort = number
      })
    })
    sidecar_proxy = object({
      name      = string
      image     = string
      essential = bool
      memory    = number
      user      = string
      healthCheck = object({
        command     = list(string)
        interval    = number
        retries     = number
        timeout     = number
        startPeriod = number
      })
      environment = list(object({
        name  = string
        value = string
      }))
    })
    routers = list(object({
      name = string
      route = object({
        spec = object({
          http_route = object({
            method = string
            scheme = string
            match = object({
              prefix = string
              header = list(object({
                name = string
                match = object({
                  prefix = string
                })
              }))
            })
            action = object({
              weighted_target = list(object({
                virtual_node = string
                weight       = number
              }))
            })
          })
        })
      })
    }))
  })
  default = null
}
