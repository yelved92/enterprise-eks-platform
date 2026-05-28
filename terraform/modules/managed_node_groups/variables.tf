# =============================================================================
# Managed Node Groups Module - Variables
# =============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster to attach nodes to"
  type        = string
}

variable "node_group_name" {
  description = "Name of the node group"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group (private app subnets)"
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Disk size in GiB for node group instances"
  type        = number
  default     = 50
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for EBS encryption"
  type        = string
}

variable "scaling_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "scaling_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 6
}

variable "scaling_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during rolling updates"
  type        = number
  default     = 33
}

variable "use_spot" {
  description = "Use Spot instances for the node group"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Additional Kubernetes labels for the node group"
  type        = map(string)
  default     = {}
}

variable "cluster_depends_on" {
  description = "Set of cluster dependencies to ensure proper ordering"
  type        = any
  default     = []
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}


variable "cluster_version" {
  description = "Kubernetes version for the node group (must match cluster version)"
  type        = string
  default     = null
}