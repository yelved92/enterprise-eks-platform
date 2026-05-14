# =============================================================================
# IAM Module - Outputs
# =============================================================================

output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.name
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the EKS node IAM role"
  value       = aws_iam_role.node.name
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = try(aws_iam_role.ebs_csi[0].arn, null)
}

output "ebs_csi_role_name" {
  description = "Name of the EBS CSI driver IAM role"
  value       = try(aws_iam_role.ebs_csi[0].name, null)
}