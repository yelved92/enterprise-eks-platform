# =============================================================================
# Subnets Module - Outputs
# =============================================================================

output "subnet_ids" {
  description = "Map of subnet type to list of subnet IDs"
  value = {
    for type, cidrs in var.cidr_blocks : type => [
      for idx in range(length(cidrs)) : aws_subnet.this["${type}-${idx}"].id
    ]
  }
}

output "subnet_arns" {
  description = "Map of subnet type to list of subnet ARNs"
  value = {
    for type, cidrs in var.cidr_blocks : type => [
      for idx in range(length(cidrs)) : aws_subnet.this["${type}-${idx}"].arn
    ]
  }
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = try(var.cidr_blocks["public"], null) != null ? [for idx in range(length(var.cidr_blocks["public"])) : aws_subnet.this["public-${idx}"].id] : []
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = try(var.cidr_blocks["private_app"], null) != null ? [for idx in range(length(var.cidr_blocks["private_app"])) : aws_subnet.this["private_app-${idx}"].id] : []
}

output "private_data_subnet_ids" {
  description = "List of private data subnet IDs"
  value       = try(var.cidr_blocks["private_data"], null) != null ? [for idx in range(length(var.cidr_blocks["private_data"])) : aws_subnet.this["private_data-${idx}"].id] : []
}

output "subnet_cidr_blocks" {
  description = "Map of subnet type to list of CIDR blocks"
  value       = var.cidr_blocks
}

output "subnet_az_mapping" {
  description = "Map of subnet type to list of availability zones"
  value = {
    for type, cidrs in var.cidr_blocks : type => [
      for idx in range(length(cidrs)) : aws_subnet.this["${type}-${idx}"].availability_zone
    ]
  }
}