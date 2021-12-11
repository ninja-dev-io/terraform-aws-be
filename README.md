# terraform-aws-be
backend IaC

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_db_instance.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_instance.replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.parameter_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_ecr_lifecycle_policy.ecr_lifecycle_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecr"></a> [ecr](#input\_ecr) | n/a | <pre>object({<br>    name                 = string<br>    image_tag_mutability = string<br>    lifecycle_policy = object({<br>      rules = list(object({<br>        rulePriority = number<br>        description  = string<br>        action = object({<br>          type = string<br>        })<br>        selection = object({<br>          tagStatus   = string<br>          countType   = string<br>          countNumber = number<br>        })<br>      }))<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_ecs"></a> [ecs](#input\_ecs) | n/a | <pre>object({<br>    cluster_name                       = string<br>    service_name                       = string<br>    container_name                     = string<br>    family                             = string<br>    network_mode                       = string<br>    requires_compatibilities           = list(string)<br>    cpu                                = number<br>    memory                             = number<br>    desired_count                      = number<br>    deployment_minimum_healthy_percent = number<br>    deployment_maximum_percent         = number<br>    launch_type                        = string<br>    scheduling_strategy                = string<br>    execution_role                     = string<br>    task_role                          = string<br>    container_definitions = list(object({<br>      image     = string<br>      essential = bool<br>      portMappings = list(object({<br>        protocol      = string<br>        containerPort = number<br>        hostPort      = number<br>      }))<br>    }))<br>    network_configuration = object({<br>      security_groups  = list(string)<br>      subnets          = list(string)<br>      assign_public_ip = bool<br>    })<br>    load_balancer = object({<br>      target_group   = string<br>      container_name = string<br>      container_port = number<br>    })<br>    autoscaling = object({<br>      max_capacity = number<br>      min_capacity = number<br>      policies = list(object({<br>        name                   = string<br>        policy_type            = string<br>        predefined_metric_type = string<br>        target_value           = number<br>      }))<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_rds"></a> [rds](#input\_rds) | n/a | <pre>object({<br>    identifier              = string<br>    instance_class          = string<br>    allocated_storage       = number<br>    engine                  = string<br>    engine_version          = string<br>    az                      = string<br>    multi_az                = bool<br>    username                = string<br>    password                = string<br>    subnets                 = list(string)<br>    security_groups         = list(string)<br>    publicly_accessible     = bool<br>    skip_final_snapshot     = bool<br>    apply_immediately       = bool<br>    backup_retention_period = number<br>    parameter_groups = list(object({<br>      name = string<br>      parameters = list(object({<br>        name  = string<br>        value = string<br>      }))<br>    }))<br>    replicas = list(object({<br>      instance_class      = string<br>      az                  = string<br>      skip_final_snapshot = bool<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_roles"></a> [roles](#input\_roles) | n/a | `map(string)` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | `map(string)` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | `map(string)` | n/a | yes |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | n/a | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rds_hostname"></a> [rds\_hostname](#output\_rds\_hostname) | RDS instance hostname |
| <a name="output_rds_port"></a> [rds\_port](#output\_rds\_port) | RDS instance port |
| <a name="output_rds_username"></a> [rds\_username](#output\_rds\_username) | RDS instance root username |
<!-- END_TF_DOCS -->