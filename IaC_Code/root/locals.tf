locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  aws_region  = data.aws_region.current.name
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  db_port = var.engine == "aurora-mysql" ? 3306 : 5432
  
}