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
  description = "List of public subnet IDs (used for IGW lifecycle ordering)"
  type        = list(string)
}

variable "public_subnet_id" {
  description = "Single public subnet ID for NAT Instance placement"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs for NAT Instance security group ingress"
  type        = list(string)
}

variable "enable_nat_instance" {
  description = "Enable NAT Instance instead of NAT Gateway (cost optimization)"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "Instance type for the NAT Instance"
  type        = string
  default     = "t3.micro"
}

variable "management_cidr" {
  description = "CIDR block allowed to SSH into the NAT Instance"
  type        = string
  default     = "0.0.0.0/0"
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