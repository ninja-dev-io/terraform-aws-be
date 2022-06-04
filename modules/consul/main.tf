locals {
  gossip_encryption_enabled = var.gossip_key_secret_arn != ""
  load_balancer = var.lb_enabled ? [{
    target_group_arn = var.target_group,
    container_name   = "consul-server"
    container_port   = 8500
  }] : []
  consul_enterprise_enabled = var.consul_license != ""
  log_configuration         = { logDriver = "awslogs", options = { awslogs-group = "consul-server-${var.env}", awslogs-region = data.aws_region.current.name, awslogs-stream-prefix = "ecs" } }
  server_dns                = "${aws_service_discovery_service.server.name}.${aws_service_discovery_private_dns_namespace.server.name}"
}

data "aws_region" "current" {}

resource "tls_private_key" "ca" {
  count       = var.tls ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  count           = var.tls ? 1 : 0
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.ca[count.index].private_key_pem

  subject {
    common_name  = "Consul Agent CA"
    organization = "HashiCorp Inc."
  }

  // 5 years.
  validity_period_hours = 43800

  is_ca_certificate  = true
  set_subject_key_id = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "aws_secretsmanager_secret" "ca_key" {
  count                   = var.tls ? 1 : 0
  name                    = "${var.name}-ca-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ca_key" {
  count         = var.tls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ca_key[count.index].id
  secret_string = tls_private_key.ca[count.index].private_key_pem
}

resource "aws_secretsmanager_secret" "ca_cert" {
  count                   = var.tls ? 1 : 0
  name                    = "${var.name}-ca-cert"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ca_cert" {
  count         = var.tls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ca_cert[count.index].id
  secret_string = tls_self_signed_cert.ca[count.index].cert_pem
}

// Optional Enterprise license.
resource "aws_secretsmanager_secret" "license" {
  count                   = local.consul_enterprise_enabled ? 1 : 0
  name                    = "${var.name}-consul-license"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "license" {
  count         = local.consul_enterprise_enabled ? 1 : 0
  secret_id     = aws_secretsmanager_secret.license[count.index].id
  secret_string = chomp(var.consul_license) // trim trailing newlines
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  network_configuration {
    subnets          = var.subnets
    assign_public_ip = var.assign_public_ip
    security_groups  = var.security_groups
  }
  launch_type = var.launch_type
  service_registries {
    registry_arn   = aws_service_discovery_service.server.arn
    container_name = "consul-server"
  }
  dynamic "load_balancer" {
    for_each = local.load_balancer
    content {
      target_group_arn = load_balancer.value["target_group_arn"]
      container_name   = load_balancer.value["container_name"]
      container_port   = load_balancer.value["container_port"]
    }
  }
  enable_execute_command = true
  wait_for_steady_state  = var.wait_for_steady_state

  depends_on = [
    aws_iam_role.this_task
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = var.requires_compatibilities
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.this_execution.arn
  task_role_arn            = aws_iam_role.this_task.arn
  volume {
    name = "consul-data"
  }
  container_definitions = jsonencode(concat(
    local.tls_init_containers,
    [
      {
        name      = "consul-server"
        image     = var.consul_image
        essential = true
        portMappings = [
          {
            containerPort = 8301
          },
          {
            containerPort = 8300
          },
          {
            containerPort = 8500
          }
        ]
        logConfiguration = local.log_configuration
        entryPoint       = ["/bin/sh", "-ec"]
        command          = [replace(local.consul_server_command, "\r", "")]
        mountPoints = [
          {
            sourceVolume  = "consul-data"
            containerPath = "/consul"
          }
        ]
        linuxParameters = {
          initProcessEnabled = true
        }
        dependsOn = var.tls ? [
          {
            containerName = "tls-init"
            condition     = "SUCCESS"
          },
        ] : []
        secrets = concat(
          local.gossip_encryption_enabled ? [
            {
              name      = "CONSUL_GOSSIP_ENCRYPTION_KEY"
              valueFrom = var.gossip_key_secret_arn
            },
          ] : [],
          var.acls ? [
            {
              name      = "CONSUL_HTTP_TOKEN"
              valueFrom = aws_secretsmanager_secret.bootstrap_token[0].arn
            },
          ] : [],
          local.consul_enterprise_enabled ? [
            {
              name      = "CONSUL_LICENSE"
              valueFrom = aws_secretsmanager_secret.license[0].arn
            },
          ] : [],
        )
      }
  ]))
}

resource "aws_iam_policy" "this_execution" {
  name        = "${var.name}_execution"
  path        = "/ecs/"
  description = "Consul server execution"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
%{if var.tls~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.ca_cert[0].arn}",
        "${aws_secretsmanager_secret.ca_key[0].arn}"
      ]
    },
%{endif~}
%{if var.acls~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.bootstrap_token[0].arn}"
      ]
    },
%{endif~}
%{if local.consul_enterprise_enabled~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.license[0].arn}"
      ]
    },
%{endif~}
%{if local.gossip_encryption_enabled~}
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${var.gossip_key_secret_arn}"
      ]
    },
%{endif~}
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "this_execution" {
  name = "${var.name}_execution"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "this_execution" {
  role       = aws_iam_role.this_execution.id
  policy_arn = aws_iam_policy.this_execution.arn
}

resource "aws_iam_role" "this_task" {
  name = "${var.name}_task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "exec"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_service_discovery_private_dns_namespace" "server" {
  name        = var.service_discovery_namespace
  description = "The namespace for the Consul dev server."
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "server" {
  name = var.name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.server.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "random_uuid" "bootstrap_token" {
  count = var.acls ? 1 : 0
}

resource "aws_secretsmanager_secret" "bootstrap_token" {
  count = var.acls ? 1 : 0
  name  = "${var.name}-bootstrap-token"
}

resource "aws_secretsmanager_secret_version" "bootstrap_token" {
  count         = var.acls ? 1 : 0
  secret_id     = aws_secretsmanager_secret.bootstrap_token[count.index].id
  secret_string = random_uuid.bootstrap_token[count.index].result
}

locals {
  consul_dns_name = "${aws_service_discovery_service.server.name}.${aws_service_discovery_private_dns_namespace.server.name}"
  // TODO: Deprecated fields
  //   The 'ca_file' field is deprecated. Use the 'tls.defaults.ca_file' field instead.
  //   The 'cert_file' field is deprecated. Use the 'tls.defaults.cert_file' field instead.
  //   The 'key_file' field is deprecated. Use the 'tls.defaults.key_file' field instead.
  //   The 'verify_incoming_rpc' field is deprecated. Use the 'tls.internal_rpc.verify_incoming' field instead.
  //   The 'verify_outgoing' field is deprecated. Use the 'tls.defaults.verify_outgoing' field instead.
  //   The 'verify_server_hostname' field is deprecated. Use the 'tls.internal_rpc.verify_server_hostname' field instead.
  //   The 'acl.tokens.master' field is deprecated. Use the 'acl.tokens.initial_management' field instead.
  consul_server_command = <<EOF
ECS_IPV4=$(curl -s $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Networks[0].IPv4Addresses[0]')
exec consul agent -server \
  -bootstrap \
  -ui \
  -advertise "$ECS_IPV4" \
  -client 0.0.0.0 \
  -data-dir /tmp/consul-data \
%{if local.gossip_encryption_enabled~}
  -encrypt "$CONSUL_GOSSIP_ENCRYPTION_KEY" \
%{endif~}
  -hcl 'telemetry { disable_compat_1.9 = true }' \
  -hcl 'connect { enabled = true }' \
  -hcl 'enable_central_service_config = true' \
%{if var.tls~}
  -hcl='ca_file = "/consul/consul-agent-ca.pem"' \
  -hcl='cert_file = "/consul/dc1-server-consul-0.pem"' \
  -hcl='key_file = "/consul/dc1-server-consul-0-key.pem"' \
  -hcl='auto_encrypt = {allow_tls = true}' \
  -hcl='ports { https = 8501 }' \
  -hcl='verify_incoming_rpc = true' \
  -hcl='verify_outgoing = true' \
  -hcl='verify_server_hostname = true' \
%{endif~}
%{if var.acls~}
  -hcl='acl {enabled = true, default_policy = "deny", down_policy = "extend-cache", enable_token_persistence = true}' \
  -hcl='acl = { tokens = { master = "${random_uuid.bootstrap_token[0].result}" }}' \
%{endif~}
EOF

  // We use this command to generate the server certs dynamically before the servers start
  // because we need to add the IP of the task as a SAN to the certificate, and we don't know that
  // IP ahead of time.
  consul_server_tls_init_command = <<EOF
ECS_IPV4=$(curl -s $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Networks[0].IPv4Addresses[0]')
cd /consul
echo "$CONSUL_CACERT_PEM" > ./consul-agent-ca.pem
echo "$CONSUL_CAKEY" > ./consul-agent-ca-key.pem
consul tls cert create -server -additional-ipaddress=$ECS_IPV4 -additional-dnsname=${local.consul_dns_name}
EOF

  tls_init_container = {
    name             = "tls-init"
    image            = var.consul_image
    essential        = false
    logConfiguration = local.log_configuration
    mountPoints = [
      {
        sourceVolume  = "consul-data"
        containerPath = "/consul"
      }
    ]
    entryPoint = ["/bin/sh", "-ec"]
    command    = [local.consul_server_tls_init_command]
    secrets = var.tls ? [
      {
        name      = "CONSUL_CACERT_PEM",
        valueFrom = aws_secretsmanager_secret.ca_cert[0].arn
      },
      {
        name      = "CONSUL_CAKEY",
        valueFrom = aws_secretsmanager_secret.ca_key[0].arn
      }
    ] : []
  }
  tls_init_containers = var.tls ? [local.tls_init_container] : []
}

resource "aws_cloudwatch_log_group" "consul_server_log" {
  name              = "consul-server-${var.env}"
  retention_in_days = 1
  depends_on = [
    aws_ecs_service.this
  ]
}
