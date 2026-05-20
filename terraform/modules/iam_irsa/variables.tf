# =============================================================================
# IAM IRSA Module - Variables
# =============================================================================
# This module creates IAM roles that are assumed by Kubernetes ServiceAccounts
# via the EKS OIDC provider (IRSA = IAM Roles for Service Accounts).
#
# It is intentionally separated from the base `iam` module so that:
#   1. Base IAM roles (cluster, nodes) can be created BEFORE the EKS cluster.
#   2. IRSA roles are created AFTER the cluster exists and the OIDC issuer
#      URL is known, avoiding a "count depends on unknown value" error.
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name prefix for all IRSA resources (typically the environment name)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider. Used as the Federated principal in IRSA trust policies."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]+:oidc-provider/", var.oidc_provider_arn))
    error_message = "oidc_provider_arn must be a valid IAM OIDC provider ARN."
  }
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL of the EKS cluster, WITHOUT the https:// scheme prefix. Used to build StringEquals conditions on :sub and :aud in IRSA trust policies."
  type        = string

  validation {
    condition     = !startswith(var.oidc_provider_url, "https://")
    error_message = "oidc_provider_url must not include the https:// scheme prefix."
  }
}

# ---- Per-role enable flags ---------------------------------------------------
variable "enable_ebs_csi_role" {
  description = "Create IRSA role for the EBS CSI controller ServiceAccount (kube-system/ebs-csi-controller-sa)."
  type        = bool
  default     = true
}

variable "enable_vpc_cni_role" {
  description = "Create IRSA role for the VPC CNI ServiceAccount (kube-system/aws-node)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all IRSA resources."
  type        = map(string)
  default     = {}
}
