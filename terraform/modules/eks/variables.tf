# =============================================================================
# EKS Module - Variables
# =============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (private app subnets)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption and log encryption"
  type        = string
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint access"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint access"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public API server endpoint"
  type        = list(string)
  default     = []
}

variable "enabled_cluster_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Retention days for CloudWatch log group"
  type        = number
  default     = 30
}

# Add-on versions (pin to specific versions for reproducibility)
variable "coredns_addon_version" {
  description = "Version of the CoreDNS EKS add-on"
  type        = string
  default     = null
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy EKS add-on"
  type        = string
  default     = null
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI EKS add-on"
  type        = string
  default     = null
}

variable "ebs_csi_addon_version" {
  description = "Version of the EBS CSI EKS add-on"
  type        = string
  default     = null
}

variable "ebs_csi_role_arn" {
  description = "ARN of the IRSA role for EBS CSI driver"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}