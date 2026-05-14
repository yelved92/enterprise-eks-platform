# =============================================================================
# Network ACLs Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all NACL resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to associate with public NACL"
  type        = list(string)
  default     = []
}

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs to associate with private app NACL"
  type        = list(string)
  default     = []
}

variable "private_data_subnet_ids" {
  description = "List of private data subnet IDs to associate with private data NACL"
  type        = list(string)
  default     = []
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "tags" {
  description = "Additional tags for all NACL resources"
  type        = map(string)
  default     = {}
}
