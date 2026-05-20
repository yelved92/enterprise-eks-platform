# =============================================================================
# EKS Module - Main Resources
# =============================================================================
# Creates a complete EKS cluster with OIDC provider, CloudWatch logging,
# and add-on management. Designed to be reusable for single-cluster dev
# and future Blue/Green deployments.
# -----------------------------------------------------------------------------

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# CloudWatch Log Group for EKS Control Plane Logs
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(
    {
      Name        = "/aws/eks/${var.cluster_name}/cluster"
      Environment = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : []
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = merge(
    {
      Name        = var.cluster_name
      Environment = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.tags
  )

  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}

# ------------------------------------------------------------------------------
# OIDC Provider (for IRSA)
# ------------------------------------------------------------------------------
data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(
    {
      Name        = "${var.cluster_name}-oidc"
      Environment = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# EKS Add-ons (CoreDNS, kube-proxy, vpc-cni)
# ------------------------------------------------------------------------------
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  addon_version               = var.coredns_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-coredns"
      Environment = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-kube-proxy"
      Environment = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Configure VPC CNI to use prefix delegation for improved IP utilization
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-vpc-cni"
      Environment = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}