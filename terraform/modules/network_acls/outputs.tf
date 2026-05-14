# =============================================================================
# Network ACLs Module - Outputs
# =============================================================================

output "public_network_acl_id" {
  description = "The ID of the public network ACL"
  value       = length(var.public_subnet_ids) > 0 ? aws_network_acl.public[0].id : null
}

output "private_network_acl_id" {
  description = "The ID of the private network ACL"
  value       = length(var.private_app_subnet_ids) > 0 ? aws_network_acl.private[0].id : null
}
