# =============================================================================
# KMS Module - Outputs
# =============================================================================

output "kms_key_id" {
  description = "The ID of the default KMS key"
  value       = aws_kms_key.this.key_id
}

output "kms_key_arn" {
  description = "The ARN of the default KMS key"
  value       = aws_kms_key.this.arn
}

output "ebs_kms_key_id" {
  description = "The ID of the EBS KMS key"
  value       = try(aws_kms_key.ebs[0].key_id, null)
}

output "ebs_kms_key_arn" {
  description = "The ARN of the EBS KMS key"
  value       = try(aws_kms_key.ebs[0].arn, null)
}

output "kms_key_alias" {
  description = "The alias of the default KMS key"
  value       = aws_kms_alias.this.name
}