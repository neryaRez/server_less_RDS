variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev or prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "master_username" {
  description = "Master username for the RDS cluster"
  type        = string
}

variable "manage_master_user_password" {
  description = "Let AWS manage the master password in Secrets Manager"
  type        = bool
  default     = true
}

variable "master_password" {
  description = "Master password for the RDS cluster when AWS-managed password is disabled"
  type        = string
  sensitive   = true
  default     = null
}

variable "master_user_secret_kms_key_id" {
  description = "Optional KMS key ID for the AWS-managed master user secret"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID where the RDS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups that are allowed to access the database"
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "Aurora database engine"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Aurora engine version"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "serverlessv2_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity in ACUs"
  type        = number
  default     = 0.5
}

variable "serverlessv2_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity in ACUs"
  type        = number
  default     = 2
}