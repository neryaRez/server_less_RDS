variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default = "Aurora_serverless_Project"
}

variable "environment" {
  description = "Environment name"
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
  description = "Master username"
  type        = string
  default = "admin"
}

variable "engine" {
  description = "Aurora engine"
  type        = string
}

variable "engine_version" {
  description = "Aurora engine version"
  type        = string
  default     = null
}

variable "serverlessv2_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity"
  type        = number
  default     = 0.5
}

variable "serverlessv2_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity"
  type        = number
  default     = 2
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default = "10.0.0.0/16"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string
  default     = "10.0.2.0/24"
}
