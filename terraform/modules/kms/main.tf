data "aws_caller_identity" "current" {}

# =============================================================================
# KMS Module - Main Resources
# =============================================================================
# Creates KMS keys for EBS encryption, S3, and other AWS services.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Default KMS Key for the environment
# ------------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  description             = var.description != null ? var.description : "KMS key for ${var.name} environment"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  key_usage               = var.key_usage
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.name}-default"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}-default"
  target_key_id = aws_kms_key.this.key_id
}

# ------------------------------------------------------------------------------
# EBS KMS Key (used by EKS node groups)
# ------------------------------------------------------------------------------
resource "aws_kms_key" "ebs" {
  count = var.enable_default_ebs_key ? 1 : 0

  description             = "KMS key for EBS encryption - ${var.name}"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  key_usage               = "ENCRYPT_DECRYPT"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 to use the key for EBS volumes"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.name}-ebs"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_kms_alias" "ebs" {
  count = var.enable_default_ebs_key ? 1 : 0

  name          = "alias/${var.name}-ebs"
  target_key_id = aws_kms_key.ebs[0].key_id
}

