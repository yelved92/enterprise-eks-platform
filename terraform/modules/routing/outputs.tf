# =============================================================================
# Routing Module - Outputs
# =============================================================================

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = length(var.public_subnet_ids) > 0 ? aws_route_table.public[0].id : null
}

output "private_app_route_table_ids" {
  description = "List of private app route table IDs"
  value       = var.create_private_route_tables ? aws_route_table.private_app[*].id : []
}

output "private_data_route_table_ids" {
  description = "List of private data route table IDs"
  value       = var.create_private_route_tables ? aws_route_table.private_data[*].id : []
}