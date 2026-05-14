# =============================================================================
# Security Groups Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all security group resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC for internal traffic rules"
  type        = string
}

variable "enable_https_ingress" {
  description = "Enable HTTPS ingress from the internet (for ALB/ingress controller)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all security group resources"
  type        = map(string)
  default     = {}
}