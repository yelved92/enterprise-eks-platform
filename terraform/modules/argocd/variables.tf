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

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}