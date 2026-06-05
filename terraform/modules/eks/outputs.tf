# =============================================================================
# EKS Module - Outputs
# =============================================================================

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The API server endpoint URL"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for control plane logs"
  value       = aws_cloudwatch_log_group.this.name
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.security_group_ids[0]
}

output "coredns_addon_version" {
  description = "Version of installed CoreDNS add-on"
  value       = try(aws_eks_addon.coredns.addon_version, null)
}

output "vpc_cni_addon_version" {
  description = "Version of installed VPC CNI add-on"
  value       = try(aws_eks_addon.vpc_cni.addon_version, null)
}

