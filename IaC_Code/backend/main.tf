terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "serverless-rds"
}

variable "bucket_prefix" {
  type    = string
  default = "tfstate"
}

variable "lock_table_prefix" {
  type    = string
  default = "terraform-locks"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  normalized_project = lower(replace(var.project_name, "_", "-"))

  bucket_name = lower(
    "${local.normalized_project}-${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  )

  dynamodb_table_name = lower(
    "${local.normalized_project}-${var.lock_table_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  )
}

resource "aws_s3_bucket" "tfstate" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "tfstate_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.lock.name
}

output "aws_region" {
  value = var.aws_region
}