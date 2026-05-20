# =============================================================================
# EKS Module - Provider Requirements
# =============================================================================
# This module uses the `tls` provider to fetch the OIDC issuer certificate
# thumbprint required by the AWS OIDC provider resource for IRSA.
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
