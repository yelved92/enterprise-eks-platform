# =============================================================================
# IAM IRSA Module - Main Resources
# =============================================================================
# Creates IAM roles consumable by Kubernetes ServiceAccounts via the EKS OIDC
# provider. Each trust policy enforces BOTH `:sub` (ServiceAccount identity)
# and `:aud = sts.amazonaws.com` (audience) to ensure least-privilege.
#
# References:
#   https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# EBS CSI Driver IRSA Role
# ------------------------------------------------------------------------------
# Assumed by the `ebs-csi-controller-sa` ServiceAccount in kube-system.
# AWS-managed policy `AmazonEBSCSIDriverPolicy` grants the controller permission
# to create/attach/snapshot EBS volumes on behalf of PersistentVolumeClaims.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ebs_csi" {
  count = var.enable_ebs_csi_role ? 1 : 0

  name        = "${var.name}-ebs-csi-driver"
  description = "IRSA role assumed by the EBS CSI controller ServiceAccount"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-ebs-csi-driver"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_ebs_csi_role ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ------------------------------------------------------------------------------
# VPC CNI IRSA Role
# ------------------------------------------------------------------------------
# Assumed by the `aws-node` ServiceAccount in kube-system. Moving CNI
# permissions off the node instance role to a ServiceAccount role is the
# AWS-recommended posture (defense-in-depth: a compromised pod cannot escalate
# to manipulate ENIs via the node's instance profile).
# ------------------------------------------------------------------------------
resource "aws_iam_role" "vpc_cni" {
  count = var.enable_vpc_cni_role ? 1 : 0

  name        = "${var.name}-vpc-cni"
  description = "IRSA role assumed by the aws-node (VPC CNI) ServiceAccount"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-vpc-cni"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  count = var.enable_vpc_cni_role ? 1 : 0

  role       = aws_iam_role.vpc_cni[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
