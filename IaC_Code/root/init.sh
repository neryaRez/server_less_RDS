#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
STATE_KEY="${2:-root/${ENVIRONMENT}/terraform.tfstate}"
BACKEND_PROJECT_NAME="${BACKEND_PROJECT_NAME:-serverless-rds}"
AWS_REGION="${AWS_REGION:-us-east-1}"

aws sts get-caller-identity > /dev/null 2>&1 || {
  echo "❌ AWS CLI not configured. Run aws configure first."
  exit 1
}

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BUCKET="${BACKEND_PROJECT_NAME}-tfstate-${ACCOUNT_ID}-${AWS_REGION}"
LOCK_TABLE="${BACKEND_PROJECT_NAME}-terraform-locks-${ACCOUNT_ID}-${AWS_REGION}"

echo "🔹 Initializing backend Terraform stack..."
echo "   Bucket: ${BUCKET}"
echo "   Lock table: ${LOCK_TABLE}"
echo "   Region: ${AWS_REGION}"
echo "   State key: ${STATE_KEY}"

terraform init -reconfigure \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="encrypt=true"

echo "✅ Terraform backend initialized successfully."