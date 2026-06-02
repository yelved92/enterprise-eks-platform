# =============================================================================
# ArgoCD Module - Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace to deploy ArgoCD into"
  type        = string
  default     = "argocd"
}

variable "cluster_name" {
  description = "Name of the EKS cluster (used for internal DNS domain)"
  type        = string
}

variable "argocd_helm_version" {
  description = "Version of the argo-cd Helm chart to deploy"
  type        = string
  default     = "5.46.0"
}

variable "git_repo_url" {
  description = "URL of the Git repository for ArgoCD to sync from"
  type        = string
}

variable "git_repo_name" {
  description = "Name/label for the Git repository in ArgoCD"
  type        = string
  default     = "enterprise-eks-platform"
}

variable "admin_user" {
  description = "GitHub username or identity to grant ArgoCD admin access"
  type        = string
  default     = "admin"
}

variable "argocd_domain" {
  description = "External domain for ArgoCD (e.g., argocd.IP.nip.io). Enables NLB + ingress when set."
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# OAuth / Dex Variables (Phase 4B)
# ------------------------------------------------------------------------------

variable "oauth_enabled" {
  description = "Enable GitHub OAuth SSO via Dex"
  type        = bool
  default     = false
}

variable "oauth_client_id" {
  description = "GitHub OAuth App Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oauth_client_secret" {
  description = "GitHub OAuth App Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oauth_org" {
  description = "Restrict GitHub OAuth to a specific organization (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}