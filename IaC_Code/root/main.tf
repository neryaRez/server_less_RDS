locals {
  serverlessv2_min_capacity = var.environment == "prod" ? 1 : 0.5
  serverlessv2_max_capacity = var.environment == "prod" ? 4 : 1
  deletion_protection       = var.environment == "prod" ? true : false
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for Aurora cluster and master user secret"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-rds-kms"
    Component = "security"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
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

  manage_master_user_password = true
  master_password             = null
  kms_key_arn                 = aws_kms_key.rds.arn

  tags = merge(local.common_tags, {
    Component = "database"
    Name      = "${local.name_prefix}-aurora"
  })
}