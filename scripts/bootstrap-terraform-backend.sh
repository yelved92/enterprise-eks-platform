#!/usr/bin/env bash
# =============================================================================
# Bootstrap Terraform Remote State Backend
# =============================================================================
# Creates S3 bucket for Terraform state storage and DynamoDB table for state
# locking. This is a one-time bootstrap step that requires AWS Console or
# AWS CLI with appropriate permissions.
#
# Usage:
#   ./scripts/bootstrap-terraform-backend.sh <environment>
#
# Example:
#   ./scripts/bootstrap-terraform-backend.sh dev
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - AWS credentials with permissions to create S3 buckets and DynamoDB tables
#   - AWS account ID known (will be fetched automatically)
#
# Output:
#   - S3 bucket: enterprise-eks-platform-tfstate-<account_id>-<region>
#   - DynamoDB table: terraform-state-lock
# =============================================================================

set -euo pipefail

# --- Configuration -----------------------------------------------------------
ENVIRONMENT="${1:-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"
BUCKET_PREFIX="enterprise-eks-platform-tfstate"
DYNAMODB_TABLE="terraform-state-lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Helper Functions --------------------------------------------------------
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# --- Pre-flight Checks -------------------------------------------------------
command -v aws >/dev/null 2>&1 || error "AWS CLI is required but not installed."
command -v jq >/dev/null 2>&1 || warn "jq is recommended but not installed."

# Validate AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || error "AWS credentials not configured or insufficient permissions."

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${BUCKET_PREFIX}-${ACCOUNT_ID}-${AWS_REGION}"

info "AWS Account ID: ${ACCOUNT_ID}"
info "AWS Region:     ${AWS_REGION}"
info "Environment:    ${ENVIRONMENT}"
info "S3 Bucket:      ${BUCKET_NAME}"
info "DynamoDB Table: ${DYNAMODB_TABLE}"

# --- Create S3 Bucket --------------------------------------------------------
info "Creating S3 bucket for Terraform state..."

if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    warn "S3 bucket '${BUCKET_NAME}' already exists. Skipping creation."
else
    if [ "${AWS_REGION}" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${AWS_REGION}" \
            --acl private
    else
        aws s3api create-bucket \
            --bucket "${BUCKET_NAME}" \
            --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}" \
            --acl private
    fi
    info "S3 bucket '${BUCKET_NAME}' created."
fi

# --- Enable S3 Bucket Features -----------------------------------------------
info "Configuring S3 bucket features..."

# Enable versioning (required for state rollback)
aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled
info "Versioning enabled."

# Enable server-side encryption (SSE-S3)
aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
info "Server-side encryption enabled (AES256)."

# Block public access
aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
info "Public access blocked."

# --- Create DynamoDB Table ---------------------------------------------------
info "Creating DynamoDB table for state locking..."

if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" 2>/dev/null; then
    warn "DynamoDB table '${DYNAMODB_TABLE}' already exists. Skipping creation."
else
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}"
    info "DynamoDB table '${DYNAMODB_TABLE}' created (on-demand billing)."

    # Wait for table to become active
    info "Waiting for DynamoDB table to become active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}"
    info "DynamoDB table is active."
fi

# --- Output ------------------------------------------------------------------
echo ""
info "============================================"
info "  Bootstrap Complete!"
info "============================================"
echo ""
info "S3 Bucket:       ${BUCKET_NAME}"
info "DynamoDB Table:  ${DYNAMODB_TABLE}"
info "AWS Region:      ${AWS_REGION}"
echo ""
info "Next steps:"
info "  1. Update terraform/backend.tf with the bucket name above"
info "  2. Run 'terraform init' in each environment directory"
echo ""
info "Backend configuration template:"
echo ""
cat <<TEMPLATE
terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "${ENVIRONMENT}/terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${DYNAMODB_TABLE}"
    encrypt        = true
  }
}
TEMPLATE
echo ""
TEMPLATE