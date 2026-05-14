# =============================================================================
# VPC Endpoints Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all VPC endpoint resources"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs for interface endpoints"
  type        = list(string)
}

variable "private_data_subnet_ids" {
  description = "List of private data subnet IDs for gateway endpoints"
  type        = list(string)
}

variable "private_app_route_table_ids" {
  description = "List of private app route table IDs for gateway endpoint associations"
  type        = list(string)
  default     = []
}

variable "private_data_route_table_ids" {
  description = "List of private data route table IDs for gateway endpoint associations"
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "Security group ID for interface endpoints"
  type        = string
  default     = null
}

variable "enable_s3_gateway_endpoint" {
  description = "Enable S3 Gateway Endpoint"
  type        = bool
  default     = true
}

variable "enable_dynamodb_gateway_endpoint" {
  description = "Enable DynamoDB Gateway Endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_api_endpoint" {
  description = "Enable ECR API Interface Endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_dkr_endpoint" {
  description = "Enable ECR DKR Interface Endpoint"
  type        = bool
  default     = true
}

variable "enable_ssm_endpoint" {
  description = "Enable SSM Interface Endpoint"
  type        = bool
  default     = true
}

variable "enable_kms_endpoint" {
  description = "Enable KMS Interface Endpoint"
  type        = bool
  default     = true
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs Interface Endpoint"
  type        = bool
  default     = true
}

variable "enable_sts_endpoint" {
  description = "Enable STS Interface Endpoint"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all VPC endpoint resources"
  type        = map(string)
  default     = {}
}