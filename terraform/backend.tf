# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Remote state storage in S3 with DynamoDB locking.
#
# IMPORTANT: Before running terraform init, you must first create the S3 bucket
# and DynamoDB table using the bootstrap script:
#
#   ./scripts/bootstrap-terraform-backend.sh <environment>
#
# The bucket name follows the pattern: enterprise-eks-platform-tfstate-<account_id>-<region>
# Update the bucket value below after running the bootstrap script.
# =============================================================================

terraform {
  backend "s3" {
    # Update these values after running the bootstrap script
    bucket         = "enterprise-eks-platform-tfstate-CHANGE_ME-us-east-1"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true

    # Optional: Enable state file locking with DynamoDB
    # Optional: Use S3 bucket key for encryption
  }
}