locals {
  serverlessv2_min_capacity = var.environment == "prod" ? 1 : 0.5
  serverlessv2_max_capacity = var.environment == "prod" ? 4 : 1
  deletion_protection       = var.environment == "prod" ? true : false
}

module "rds_cluster" {
  source = "../modules/rds-cluster"

  project_name = var.project_name
  environment  = var.environment

  db_name         = var.db_name
  master_username = var.master_username

  engine         = var.engine
  engine_version = var.engine_version

  vpc_id = aws_vpc.serverless_vpc.id
  private_subnet_ids = [
    aws_subnet.private_rds_a.id,
    aws_subnet.private_rds_b.id
  ]

  allowed_security_group_ids = []

  backup_retention_period = var.backup_retention_period
  deletion_protection     = local.deletion_protection

  serverlessv2_min_capacity = local.serverlessv2_min_capacity
  serverlessv2_max_capacity = local.serverlessv2_max_capacity

  tags = merge(local.common_tags, {
    Component = "database"
    Name      = "${local.name_prefix}-aurora"
  })
}