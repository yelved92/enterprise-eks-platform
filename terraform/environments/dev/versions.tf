# =============================================================================
# Dev Environment - Terraform & Provider Version Constraints
# =============================================================================
# Pin Terraform CLI and provider versions to ensure reproducible builds across
# developer workstations and CI/CD runners. Constraints are deliberately
# permissive within the current major version to allow patch/minor upgrades.
#
# Current resolved versions (from .terraform.lock.hcl) at time of creation:
#   - aws    = 6.45.0
#   - random = 3.9.0
#   - tls    = 4.3.0
#   - helm   = 2.14.0 (approx)
#   - kubernetes = 2.30.0 (approx)
#
# To upgrade providers intentionally:
#   1. Bump the constraint here (or use `terraform init -upgrade`)
#   2. Commit the updated .terraform.lock.hcl
#   3. Open a PR so peers see the version bump
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}