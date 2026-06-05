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

# ------------------------------------------------------------------------------
# Cert-Manager IRSA Role (Route53 DNS-01 challenge)
# ------------------------------------------------------------------------------
# Assumed by the `cert-manager` ServiceAccount in cert-manager namespace.
# Grants Route53 permissions needed for Let's Encrypt DNS-01 ACME challenges
# (wildcard certificate issuance for *.yelved.xyz).
# ------------------------------------------------------------------------------
resource "aws_iam_role" "cert_manager" {
  count = var.enable_cert_manager_role ? 1 : 0

  name        = "${var.name}-cert-manager"
  description = "IRSA role assumed by cert-manager ServiceAccount for Route53 DNS-01 challenges"

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
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:cert-manager:cert-manager"
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-cert-manager"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

# Custom IAM policy: Route53 record management for DNS-01 challenges
resource "aws_iam_policy" "cert_manager_route53" {
  count = var.enable_cert_manager_role ? 1 : 0

  name        = "${var.name}-cert-manager-route53"
  description = "Allows cert-manager to manage Route53 DNS records for Let's Encrypt DNS-01 validation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ListHostedZones"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-cert-manager-route53"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "cert_manager_route53" {
  count = var.enable_cert_manager_role ? 1 : 0

  role       = aws_iam_role.cert_manager[0].name
  policy_arn = aws_iam_policy.cert_manager_route53[0].arn
}

# ------------------------------------------------------------------------------
# External Secrets Operator IRSA Role (Secrets Manager read)
# ------------------------------------------------------------------------------
# Assumed by the `external-secrets-sa` ServiceAccount in test-secrets namespace.
# Grants read-only permissions to AWS Secrets Manager for syncing secrets
# into Kubernetes using External Secrets Operator.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "external_secrets" {
  count = var.enable_external_secrets_role ? 1 : 0

  name        = "${var.name}-external-secrets"
  description = "IRSA role assumed by External Secrets Operator ServiceAccount for Secrets Manager access"

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
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:test-secrets:external-secrets-sa"
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-external-secrets"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

# Custom IAM policy: Read-only access to AWS Secrets Manager
resource "aws_iam_policy" "external_secrets" {
  count = var.enable_external_secrets_role ? 1 : 0

  name        = "${var.name}-external-secrets-sm-read"
  description = "Allows External Secrets Operator to read secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = ["*"]
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-external-secrets-sm-read"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count = var.enable_external_secrets_role ? 1 : 0

  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}

# ------------------------------------------------------------------------------
# AWS Load Balancer Controller IRSA Role
# ------------------------------------------------------------------------------
# Assumed by the `aws-load-balancer-controller-sa` ServiceAccount in kube-system.
# The controller manages NLB/ALB target groups, enabling IP target mode so
# that NLBs route traffic directly to pod IPs instead of NodePorts.
# AWS-managed policy `AmazonEKSLoadBalancerControllerPolicy` grants full
# permissions to manage ELBv2 (NLB/ALB) resources.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "aws_lb_controller" {
  count = var.enable_load_balancer_controller_role ? 1 : 0

  name        = "${var.name}-aws-lb-controller"
  description = "IRSA role assumed by AWS Load Balancer Controller ServiceAccount"

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
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller-sa"
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-aws-lb-controller"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

# Custom IAM policy for AWS Load Balancer Controller
# Source: https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
# This is NOT an AWS-managed policy — it must be created as a customer-managed policy.
resource "aws_iam_policy" "aws_lb_controller" {
  count = var.enable_load_balancer_controller_role ? 1 : 0

  name        = "${var.name}-aws-lb-controller"
  description = "IAM policy for AWS Load Balancer Controller — manages ELBv2, EC2 security groups, and related resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:CreateServiceLinkedRole"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:DescribeIpamPools",
          "ec2:DescribeRouteTables",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTrustStores",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DescribeCapacityReservation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["ec2:CreateSecurityGroup"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["ec2:CreateTags"]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["ec2:CreateTags", "ec2:DeleteTags"]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyListenerAttributes",
          "elasticloadbalancing:ModifyCapacityReservation",
          "elasticloadbalancing:ModifyIpPools"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["elasticloadbalancing:AddTags"]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          StringEquals = {
            "elasticloadbalancing:CreateAction" = [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name      = "${var.name}-aws-lb-controller"
      ManagedBy = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  count = var.enable_load_balancer_controller_role ? 1 : 0

  role       = aws_iam_role.aws_lb_controller[0].name
  policy_arn = aws_iam_policy.aws_lb_controller[0].arn
}
