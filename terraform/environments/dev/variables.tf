# =============================================================================
# Dev Environment - Variables
# =============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
  default     = "yelved.xyz"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# EKS Cluster Variables
# ------------------------------------------------------------------------------
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_log_retention_days" {
  description = "Retention days for EKS control plane CloudWatch logs"
  type        = number
  default     = 30
}

variable "enabled_cluster_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
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

# ------------------------------------------------------------------------------
# Managed Node Group Variables
# ------------------------------------------------------------------------------
variable "node_group_name" {
  description = "Name of the managed node group"
  type        = string
  default     = "dev-node-group"
}

variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for node group instances"
  type        = number
  default     = 50
}

variable "node_group_scaling_desired" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "node_group_scaling_max" {
  description = "Maximum number of nodes"
  type        = number
  default     = 6
}

variable "node_group_scaling_min" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "use_spot_instances" {
  description = "Use Spot instances for the node group"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default = {
    Project     = "enterprise-eks-platform"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}


