variable "rds" {
  type = object({
    identifier              = string
    instance_class          = string
    allocated_storage       = number
    engine                  = string
    engine_version          = string
    az                      = string
    multi_az                = bool
    username                = string
    password                = string
    subnets                 = list(string)
    security_groups         = list(string)
    publicly_accessible     = bool
    skip_final_snapshot     = bool
    apply_immediately       = bool
    backup_retention_period = number
    parameter_groups = list(object({
      name = string
      parameters = list(object({
        name  = string
        value = string
      }))
    }))
    replicas = list(object({
      instance_class      = string
      az                  = string
      skip_final_snapshot = bool
    }))
  })
}


