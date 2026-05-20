# =============================================================================
# IAM Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all IAM resources"
  type        = string
}

# IRSA-related variables (eks_oidc_provider_arn, eks_oidc_provider_url, etc.)
# were moved to the dedicated `iam_irsa` module to break the count-on-unknown
# evaluation problem during the first plan. See modules/iam_irsa/.

variable "tags" {
  description = "Additional tags for all IAM resources"
  type        = map(string)
  default     = {}
}