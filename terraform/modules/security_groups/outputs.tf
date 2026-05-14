# =============================================================================
# Security Groups Module - Outputs
# =============================================================================

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "cluster_security_group_id" {
  description = "The ID of the EKS cluster security group"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "The ID of the EKS node security group"
  value       = aws_security_group.nodes.id
}

output "internal_services_security_group_id" {
  description = "The ID of the internal services security group"
  value       = aws_security_group.internal_services.id
}

output "data_security_group_id" {
  description = "The ID of the data layer security group"
  value       = aws_security_group.data.id
}

output "node_security_group_arn" {
  description = "The ARN of the node security group"
  value       = aws_security_group.nodes.arn
}
