# =============================================================================
# Terraform Version Constraints
# =============================================================================
# Defines required Terraform version and provider versions with strict
# version pinning for production reproducibility.
# =============================================================================

terraform {
  # Terraform version constraint
  required_version = "~> 1.5.0"

  # Required providers with version pinning
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}