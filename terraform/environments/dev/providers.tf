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

# =============================================================================
# Kubernetes & Helm Providers — used for ArgoCD deployment (Phase 4)
# These providers connect to the EKS cluster using the same credentials as
# kubectl. The exec-based auth ensures they stay in sync with the AWS CLI
# session (SSO, env vars, etc.).
# -----------------------------------------------------------------------------

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}