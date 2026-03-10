locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  cluster_identifier  = "${local.name_prefix}-aurora-cluster"
  subnet_group_name   = "${local.name_prefix}-db-subnet-group"
  security_group_name = "${local.name_prefix}-db-sg"

  final_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
  db_port = var.engine == "aurora-mysql" ? 3306 : 5432
  final_snapshot_identifier = "${local.name_prefix}-final-snapshot"
}