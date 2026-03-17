#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
STATE_KEY="${2:-root/${ENVIRONMENT}/terraform.tfstate}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/../backend" && pwd)"

aws sts get-caller-identity > /dev/null 2>&1 || {
  echo "❌ AWS CLI not configured. Run aws configure first."
  exit 1
}

if [ ! -f "${BACKEND_DIR}/terraform.tfstate" ]; then
  echo "❌ Backend state not found in ${BACKEND_DIR}."
  echo "Run IaC_Code/backend first."
  exit 1
fi

BUCKET="$(cd "${BACKEND_DIR}" && terraform output -raw tfstate_bucket)"
LOCK_TABLE="$(cd "${BACKEND_DIR}" && terraform output -raw dynamodb_table)"
REGION="$(cd "${BACKEND_DIR}" && terraform output -raw aws_region)"

echo "🔹 Initializing backend Terraform stack..."
echo "   Bucket: ${BUCKET}"
echo "   Lock table: ${LOCK_TABLE}"
echo "   Region: ${REGION}"
echo "   State key: ${STATE_KEY}"

cd "${SCRIPT_DIR}"

terraform init -reconfigure \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="region=${REGION}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="encrypt=true"

echo "✅ Terraform backend initialized successfully."