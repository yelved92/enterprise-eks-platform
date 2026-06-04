# =============================================================================
# Routing Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all route table resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "igw_id" {
  description = "The ID of the Internet Gateway for public route tables"
  type        = string
  default     = null
}

variable "nat_instance_eni_id" {
  description = "The primary network interface ID of the NAT Instance (for private route table default routes)"
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to associate with public route tables"
  type        = list(string)
  default     = []
}

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs to associate with private app route tables"
  type        = list(string)
  default     = []
}

variable "private_data_subnet_ids" {
  description = "List of private data subnet IDs to associate with private data route tables"
  type        = list(string)
  default     = []
}

variable "create_private_route_tables" {
  description = "Create private route tables and associations"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all routing resources"
  type        = map(string)
  default     = {}
}