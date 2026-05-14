# =============================================================================
# Dev Environment - Remote State Backend
# =============================================================================
# IMPORTANT: Run bootstrap script before using this configuration:
#   ./scripts/bootstrap-terraform-backend.sh dev
# Update the bucket name after bootstrap with your actual AWS account ID.
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "enterprise-eks-platform-tfstate-CHANGE_ME-us-east-1"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}