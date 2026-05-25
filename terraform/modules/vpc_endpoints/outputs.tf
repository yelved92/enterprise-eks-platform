# =============================================================================
# VPC Endpoints Module - Outputs
# =============================================================================

output "s3_gateway_endpoint_id" {
  description = "The ID of the S3 Gateway Endpoint"
  value       = var.enable_s3_gateway_endpoint ? aws_vpc_endpoint.s3_gateway[0].id : null
}

output "dynamodb_gateway_endpoint_id" {
  description = "The ID of the DynamoDB Gateway Endpoint"
  value       = var.enable_dynamodb_gateway_endpoint ? aws_vpc_endpoint.dynamodb_gateway[0].id : null
}
output "s3_interface_endpoint_id" {
  description = "The ID of the S3 Interface Endpoint (for HTTPS access from container runtime)"
  value       = var.enable_s3_interface_endpoint ? aws_vpc_endpoint.interface["s3"].id : null
}
output "interface_endpoint_ids" {
  description = "Map of interface endpoint names to IDs"
  value = {
    for k, ep in aws_vpc_endpoint.interface : k => ep.id
  }
}

output "interface_endpoint_arns" {
  description = "Map of interface endpoint names to ARNs"
  value = {
    for k, ep in aws_vpc_endpoint.interface : k => ep.arn
  }
}
