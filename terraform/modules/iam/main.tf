# =============================================================================
# IAM Module - Main Resources
# =============================================================================
# Creates base IAM roles and policies for the EKS platform, including
# cluster admin role, node instance role, and IRSA foundation.
# -----------------------------------------------------------------------------

data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# EKS Cluster IAM Role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.name}-eks-cluster-role"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_service_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ------------------------------------------------------------------------------
# EKS Node IAM Role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "node" {
  name = "${var.name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.name}-eks-node-role"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ------------------------------------------------------------------------------
# Node Additional Policies (EBS, CloudWatch, etc.)
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy" "node_additional" {
  name = "${var.name}-eks-node-additional"
  role = aws_iam_role.node.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:ReEncrypt*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IRSA Roles (moved to terraform/modules/iam_irsa)
# ------------------------------------------------------------------------------
# Roles assumed by Kubernetes ServiceAccounts via OIDC (EBS CSI, VPC CNI,
# ArgoCD, ExternalDNS, etc.) live in the dedicated `iam_irsa` module. They
# require the EKS OIDC provider URL, which is only known AFTER the cluster
# is created — keeping them in a separate module avoids a count-on-unknown error during the FIRST plan/apply.
# ------------------------------------------------------------------------------

