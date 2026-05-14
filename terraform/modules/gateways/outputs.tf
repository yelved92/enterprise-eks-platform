# =============================================================================
# Gateways Module - Outputs
# =============================================================================

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = var.enable_igw ? aws_internet_gateway.this[0].id : null
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = var.enable_igw ? aws_internet_gateway.this[0].arn : null
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[*].id : []
}

output "nat_gateway_public_ips" {
  description = "List of public IPs associated with NAT Gateways"
  value       = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}

output "single_nat_gateway" {
  description = "Whether a single NAT Gateway is used"
  value       = var.single_nat_gateway
}