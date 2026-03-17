resource "aws_db_subnet_group" "db_subnet_group" {
  name       = local.subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = local.final_tags
}

resource "aws_security_group" "db_security_group" {
  name        = local.security_group_name
  description = "Security group for the Aurora cluster"
  vpc_id      = var.vpc_id

  tags = local.final_tags
}

resource "aws_vpc_security_group_ingress_rule" "db_from_allowed_sgs" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.db_security_group.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = local.db_port
  to_port                      = local.db_port
  description                  = "Allow database access from approved security groups"
}

resource "aws_vpc_security_group_egress_rule" "db_all_outbound" {
  security_group_id = aws_security_group.db_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

resource "aws_rds_cluster" "db_cluster" {
  cluster_identifier = local.cluster_identifier
  engine             = var.engine
  engine_version     = var.engine_version

  database_name = var.db_name

  master_username             = var.master_username
  manage_master_user_password = var.manage_master_user_password
  master_password             = var.manage_master_user_password ? null : var.master_password

  storage_encrypted             = true
  kms_key_id                    = var.kms_key_arn
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.kms_key_arn : null

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]

  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? local.final_snapshot_identifier : null

  serverlessv2_scaling_configuration {
    min_capacity = var.serverlessv2_min_capacity
    max_capacity = var.serverlessv2_max_capacity
  }

  tags = local.final_tags
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${local.name_prefix}-writer"
  cluster_identifier = aws_rds_cluster.db_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.db_cluster.engine
  engine_version     = aws_rds_cluster.db_cluster.engine_version

  tags = local.final_tags
}