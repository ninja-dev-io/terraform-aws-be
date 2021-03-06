# terraform-aws-be
backend IaC

![logo](https://raw.githubusercontent.com/ninja-dev-io/terraform-aws-be/master/logo.jpg)

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.22.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mesh"></a> [mesh](#module\_mesh) | app.terraform.io/ninjadev/mesh/aws | 1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_instance.databases](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_instance.replicas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.parameter_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.subnet_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_ecr_lifecycle_policy.ecr_lifecycle_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_sns_topic.sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.sqs_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.sqs_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.sqs_queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_iam_policy_document.iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.master_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecr"></a> [ecr](#input\_ecr) | n/a | <pre>object({<br>    name                 = string<br>    image_tag_mutability = string<br>    lifecycle_policy = object({<br>      rules = list(object({<br>        rulePriority = number<br>        description  = string<br>        action = object({<br>          type = string<br>        })<br>        selection = object({<br>          tagStatus   = string<br>          countType   = string<br>          countNumber = number<br>        })<br>      }))<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_ecs"></a> [ecs](#input\_ecs) | n/a | <pre>object({<br>    cluster_name = string<br>    tasks = list(object({<br>      name                     = string<br>      essential                = bool<br>      network_mode             = string<br>      requires_compatibilities = list(string)<br>      cpu                      = number<br>      memory                   = number<br>      execution_role           = string<br>      task_role                = string<br>      container_definitions = list(object({<br>        name      = optional(string)<br>        image     = optional(string)<br>        command   = optional(list(string))<br>        essential = optional(bool)<br>        healthCheck = optional(object({<br>          command  = list(string)<br>          interval = number<br>          retries  = number<br>          timeout  = number<br>        }))<br>        portMappings = optional(list(object({<br>          protocol      = string<br>          containerPort = number<br>          hostPort      = number<br>        })))<br>        environment = optional(list(object({<br>          name  = string<br>          value = string<br>        })))<br>      }))<br>    }))<br>    services = list(object({<br>      name                               = string<br>      family                             = string<br>      port                               = number<br>      desired_count                      = number<br>      deployment_minimum_healthy_percent = number<br>      deployment_maximum_percent         = number<br>      launch_type                        = string<br>      scheduling_strategy                = string<br>      network_configuration = object({<br>        security_groups  = list(string)<br>        subnets          = list(string)<br>        assign_public_ip = bool<br>      })<br>      load_balancer = list(object({<br>        target_group   = string<br>        container_name = string<br>        container_port = number<br>      }))<br>      target = object({<br>        max_capacity       = number<br>        min_capacity       = number<br>        scalable_dimension = string<br>        service_namespace  = string<br>      })<br>      policies = list(object({<br>        name                   = string<br>        target                 = string<br>        policy_type            = string<br>        target                 = string<br>        predefined_metric_type = string<br>        target_value           = number<br>      }))<br>      log = object({<br>        retention_in_days = string<br>      })<br>      backend = list(string)<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_mesh"></a> [mesh](#input\_mesh) | AWS mesh configuration | <pre>object({<br>    name      = string<br>    namespace = string<br>    proxy_configuration = object({<br>      type           = string<br>      container_name = string<br>      properties = object({<br>        AppPorts         = string<br>        EgressIgnoredIPs = string<br>        IgnoredUID       = string<br>        ProxyEgressPort  = number<br>        ProxyIngressPort = number<br>      })<br>    })<br>    sidecar_proxy = object({<br>      name      = string<br>      image     = string<br>      essential = bool<br>      memory    = number<br>      user      = string<br>      healthCheck = object({<br>        command     = list(string)<br>        interval    = number<br>        retries     = number<br>        timeout     = number<br>        startPeriod = number<br>      })<br>      environment = list(object({<br>        name  = string<br>        value = string<br>      }))<br>    })<br>    routers = list(object({<br>      name = string<br>      route = object({<br>        spec = object({<br>          http_route = object({<br>            method = string<br>            scheme = string<br>            match = object({<br>              prefix = string<br>              header = list(object({<br>                name = string<br>                match = object({<br>                  prefix = string<br>                })<br>              }))<br>            })<br>            action = object({<br>              weighted_target = list(object({<br>                virtual_node = string<br>                weight       = number<br>              }))<br>            })<br>          })<br>        })<br>      })<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_rds"></a> [rds](#input\_rds) | n/a | <pre>object({<br>    databases = list(object({<br>      identifier              = string<br>      instance_class          = string<br>      allocated_storage       = number<br>      engine                  = string<br>      engine_version          = string<br>      az                      = string<br>      multi_az                = bool<br>      name                    = string<br>      username                = string<br>      subnets                 = list(string)<br>      security_groups         = list(string)<br>      publicly_accessible     = bool<br>      skip_final_snapshot     = bool<br>      parameter_group_name    = string<br>      apply_immediately       = bool<br>      backup_retention_period = number<br>    }))<br><br>    parameter_groups = list(object({<br>      name   = string<br>      family = string<br>      parameters = list(object({<br>        name  = string<br>        value = string<br>      }))<br>    }))<br><br>    replicas = list(object({<br>      identifier           = string<br>      replicate_source_db  = string<br>      instance_class       = string<br>      az                   = string<br>      skip_final_snapshot  = bool<br>      parameter_group_name = string<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_roles"></a> [roles](#input\_roles) | n/a | `map(string)` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | `map(string)` | n/a | yes |
| <a name="input_sns"></a> [sns](#input\_sns) | n/a | <pre>list(object({<br>    name                        = string<br>    delivery_policy             = string<br>    kms_master_key_id           = string<br>    fifo_topic                  = bool<br>    content_based_deduplication = bool<br>  }))</pre> | n/a | yes |
| <a name="input_sqs"></a> [sqs](#input\_sqs) | n/a | <pre>list(object({<br>    name                              = string<br>    fifo_queue                        = bool<br>    content_based_deduplication       = bool<br>    kms_master_key_id                 = string<br>    kms_data_key_reuse_period_seconds = number<br>    topics                            = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | `map(string)` | n/a | yes |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | n/a | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_databases"></a> [databases](#output\_databases) | RDS data |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | ECR repository url |
<!-- END_TF_DOCS -->
