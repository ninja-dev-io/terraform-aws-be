resource "aws_db_instance" "rds" {
  identifier              = var.rds.identifier
  instance_class          = var.rds.instance_class
  availability_zone       = !var.rds.multi_az ? var.rds.az : null
  multi_az                = var.rds.multi_az
  allocated_storage       = var.rds.allocated_storage
  engine                  = var.rds.engine
  engine_version          = var.rds.engine_version
  username                = var.rds.username
  password                = var.rds.password
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [for group in var.rds.security_groups : lookup(var.security_groups, group)]
  publicly_accessible     = var.rds.publicly_accessible
  skip_final_snapshot     = var.rds.skip_final_snapshot
  parameter_group_name    = keys(aws_db_parameter_group.parameter_group)[0]
  backup_retention_period = var.rds.backup_retention_period
  tags                    = { Name = "${var.rds.identifier}-${var.env}" }
  depends_on = [
    aws_db_parameter_group.parameter_group
  ]
}

resource "aws_db_subnet_group" "rds" {
  name       = var.rds.identifier
  subnet_ids = [for subnet in var.rds.subnets : lookup(var.subnets, subnet)]
}

resource "aws_db_parameter_group" "parameter_group" {
  for_each = { for group in var.rds.parameter_groups : group.name => group }
  name     = each.key
  family   = format("%s%s", var.rds.engine, split(".", var.rds.engine_version)[0])
  dynamic "parameter" {
    for_each = { for parameter in each.value.parameters : parameter.name => parameter }
    content {
      name  = parameter.key
      value = parameter.value.value
    }
  }
}

resource "aws_db_instance" "replica" {
  count                = length(var.rds.replicas)
  identifier           = "${var.rds.identifier}-${count.index + 1}"
  replicate_source_db  = aws_db_instance.rds.identifier
  instance_class       = element(var.rds.replicas[*].instance_class, count.index)
  availability_zone    = element(var.rds.replicas[*].az, count.index)
  skip_final_snapshot  = element(var.rds.replicas[*].skip_final_snapshot, count.index)
  apply_immediately    = true
  parameter_group_name = keys(aws_db_parameter_group.parameter_group)[1]
  tags                 = { Name = "${var.rds.identifier}-${var.env}-${count.index + 1}" }
  depends_on = [
    aws_db_parameter_group.parameter_group
  ]
}


