# =============================================================================
# Dev Environment - AWS Provider Configuration
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "enterprise-eks-platform"
    }
  }
}

provider "random" {
  # No additional configuration needed
}

provider "tls" {
  # No additional configuration needed
}