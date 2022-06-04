variable "rds" {
  type = object({
    databases = list(object({
      identifier              = string
      instance_class          = string
      allocated_storage       = number
      engine                  = string
      engine_version          = string
      az                      = string
      multi_az                = bool
      name                    = string
      username                = string
      subnets                 = list(string)
      security_groups         = list(string)
      publicly_accessible     = bool
      skip_final_snapshot     = bool
      parameter_group_name    = string
      apply_immediately       = bool
      backup_retention_period = number
    }))

    parameter_groups = list(object({
      name   = string
      family = string
      parameters = list(object({
        name  = string
        value = string
      }))
    }))

    replicas = list(object({
      identifier           = string
      replicate_source_db  = string
      instance_class       = string
      az                   = string
      skip_final_snapshot  = bool
      parameter_group_name = string
    }))
  })
}


