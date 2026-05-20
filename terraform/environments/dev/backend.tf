# =============================================================================
# Dev Environment - Remote State Backend
# =============================================================================
terraform {
  backend "s3" {
    bucket         = "enterprise-eks-platform-tfstate-704489329694-us-east-1"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }
}
