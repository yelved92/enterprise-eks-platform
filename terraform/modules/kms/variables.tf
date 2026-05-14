# =============================================================================
# KMS Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all KMS resources"
  type        = string
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = null
}

variable "key_usage" {
  description = "Intended use of the key"
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], var.key_usage)
    error_message = "Key usage must be ENCRYPT_DECRYPT or SIGN_VERIFY."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Waiting period before KMS key deletion"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "enable_default_ebs_key" {
  description = "Create a default EBS KMS key for the environment"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all KMS resources"
  type        = map(string)
  default     = {}
}