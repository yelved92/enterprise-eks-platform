# =============================================================================
# Gateways Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all gateway resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for NAT Gateway placement"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (cost optimization for lab/dev). If true, only the first public subnet is used."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway creation"
  type        = bool
  default     = true
}

variable "enable_igw" {
  description = "Enable Internet Gateway creation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all gateway resources"
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways"
  type        = map(string)
  default     = {}
}

variable "eip_tags" {
  description = "Additional tags for Elastic IPs"
  type        = map(string)
  default     = {}
}