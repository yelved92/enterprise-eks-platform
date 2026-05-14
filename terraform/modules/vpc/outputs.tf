# =============================================================================
# VPC Module - Outputs
# =============================================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table"
  value       = aws_vpc.this.main_route_table_id
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

output "enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled in the VPC"
  value       = aws_vpc.this.enable_dns_hostnames
}

output "enable_flow_logs" {
  description = "Whether VPC Flow Logs are enabled"
  value       = var.enable_flow_logs
}

output "flow_log_id" {
  description = "The ID of the flow log (if enabled)"
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_group" {
  description = "The CloudWatch log group for flow logs (if enabled)"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}