# =============================================================================
# Managed Node Groups Module - Outputs
# =============================================================================

output "node_group_id" {
  description = "The ID of the node group"
  value       = aws_eks_node_group.this.id
}

output "node_group_name" {
  description = "The name of the node group"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "The ARN of the node group"
  value       = aws_eks_node_group.this.arn
}

output "node_group_status" {
  description = "The status of the node group"
  value       = aws_eks_node_group.this.status
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}

output "scaling_config" {
  description = "The scaling configuration of the node group"
  value       = aws_eks_node_group.this.scaling_config
}