# =============================================================================
# Subnets Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all subnet resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to create subnets in"
  type        = list(string)
}

variable "cidr_blocks" {
  description = <<-EOT
    Map of subnet types to CIDR blocks per AZ.
    Example:
    {
      public       = ["10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"],
      private_app  = ["10.0.32.0/21", "10.0.40.0/21", "10.0.48.0/21"],
      private_data = ["10.0.64.0/21", "10.0.72.0/21", "10.0.80.0/21"]
    }
  EOT
  type = map(list(string))

  validation {
    condition = alltrue([
      for key, val in var.cidr_blocks : length(val) == length(var.availability_zones)
    ])
    error_message = "Each subnet type must have the same number of CIDR blocks as availability zones."
  }
}

variable "map_public_ip_on_launch" {
  description = "Whether to assign public IPs to instances in public subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all subnet resources"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_app_subnet_tags" {
  description = "Additional tags for private app subnets"
  type        = map(string)
  default     = {}
}

variable "private_data_subnet_tags" {
  description = "Additional tags for private data subnets"
  type        = map(string)
  default     = {}
}
