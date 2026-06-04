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

output "nat_instance_id" {
  description = "The ID of the NAT Instance"
  value       = var.enable_nat_instance ? aws_instance.nat_instance[0].id : null
}

output "nat_instance_eni_id" {
  description = "The primary network interface ID of the NAT Instance (for route table configuration)"
  value       = var.enable_nat_instance ? aws_instance.nat_instance[0].primary_network_interface_id : null
}

output "nat_instance_public_ip" {
  description = "The public IP of the NAT Instance"
  value       = var.enable_nat_instance ? aws_eip.nat_instance[0].public_ip : null
}