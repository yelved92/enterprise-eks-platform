# =============================================================================
# IAM Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all IAM resources"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster for IRSA trust policies"
  type        = string
  default     = null
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for all IAM resources"
  type        = map(string)
  default     = {}
}