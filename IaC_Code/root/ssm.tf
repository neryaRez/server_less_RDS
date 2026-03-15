resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/${var.project_name}/${var.environment}/database/endpoint"
  description = "Aurora cluster writer endpoint"
  type        = "String"
  value       = module.rds_cluster.cluster_endpoint

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/${var.project_name}/${var.environment}/database/port"
  description = "Aurora database port"
  type        = "String"
  value       = tostring(local.db_port)

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_engine" {
  name        = "/${var.project_name}/${var.environment}/database/engine"
  description = "Aurora database engine"
  type        = "String"
  value       = var.engine

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.project_name}/${var.environment}/database/name"
  description = "Initial database name"
  type        = "String"
  value       = var.db_name
  
  tags = local.common_tags
}