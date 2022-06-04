data "aws_ssm_parameter" "master_password" {
  for_each = { for db in var.rds.databases : db.identifier => db }
  name     = "/${var.env}/${each.key}/password/master"
}

resource "aws_db_instance" "databases" {
  for_each                = { for db in var.rds.databases : db.identifier => db }
  identifier              = each.key
  instance_class          = each.value.instance_class
  availability_zone       = !each.value.multi_az ? each.value.az : null
  multi_az                = each.value.multi_az
  allocated_storage       = each.value.allocated_storage
  engine                  = each.value.engine
  engine_version          = each.value.engine_version
  username                = each.value.username
  name                    = each.value.name
  password                = lookup(data.aws_ssm_parameter.master_password, each.key).value
  db_subnet_group_name    = lookup(aws_db_subnet_group.subnet_groups, each.key).name
  vpc_security_group_ids  = [for group in each.value.security_groups : lookup(var.security_groups, group)]
  publicly_accessible     = each.value.publicly_accessible
  skip_final_snapshot     = each.value.skip_final_snapshot
  parameter_group_name    = each.value.parameter_group_name
  backup_retention_period = each.value.backup_retention_period
  tags                    = { Name = "${each.key}-${var.env}" }
  depends_on = [
    aws_db_parameter_group.parameter_groups
  ]
}

resource "aws_db_subnet_group" "subnet_groups" {
  for_each   = { for db in var.rds.databases : db.identifier => db }
  name       = each.key
  subnet_ids = [for subnet in each.value.subnets : lookup(var.subnets, subnet)]
}

resource "aws_db_parameter_group" "parameter_groups" {
  for_each = { for group in var.rds.parameter_groups : group.name => group }
  name     = each.key
  family   = each.value.family
  dynamic "parameter" {
    for_each = { for parameter in each.value.parameters : parameter.name => parameter }
    content {
      name  = parameter.key
      value = parameter.value.value
    }
  }
}

resource "aws_db_instance" "replicas" {
  for_each             = { for replica in var.rds.replicas : replica.identifier => replica }
  identifier           = each.key
  replicate_source_db  = each.value.replicate_source_db
  instance_class       = each.value.instance_class
  availability_zone    = each.value.az
  skip_final_snapshot  = each.value.skip_final_snapshot
  apply_immediately    = true
  parameter_group_name = each.value.parameter_group_name
  tags                 = { Name = "${each.key}-${var.env}" }
  depends_on = [
    aws_db_parameter_group.parameter_groups,
    aws_db_instance.databases
  ]
}


