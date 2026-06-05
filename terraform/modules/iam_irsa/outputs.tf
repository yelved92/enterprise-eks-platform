# =============================================================================
# IAM IRSA Module - Outputs
# =============================================================================

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IRSA role (null if disabled)"
  value       = try(aws_iam_role.ebs_csi[0].arn, null)
}

output "ebs_csi_role_name" {
  description = "Name of the EBS CSI driver IRSA role (null if disabled)"
  value       = try(aws_iam_role.ebs_csi[0].name, null)
}

output "vpc_cni_role_arn" {
  description = "ARN of the VPC CNI IRSA role (null if disabled)"
  value       = try(aws_iam_role.vpc_cni[0].arn, null)
}

output "vpc_cni_role_name" {
  description = "Name of the VPC CNI IRSA role (null if disabled)"
  value       = try(aws_iam_role.vpc_cni[0].name, null)
}

output "cert_manager_role_arn" {
  description = "ARN of the cert-manager IRSA role for Route53 DNS-01 (null if disabled)"
  value       = try(aws_iam_role.cert_manager[0].arn, null)
}

output "cert_manager_role_name" {
  description = "Name of the cert-manager IRSA role (null if disabled)"
  value       = try(aws_iam_role.cert_manager[0].name, null)
}

output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IRSA role for Secrets Manager (null if disabled)"
  value       = try(aws_iam_role.external_secrets[0].arn, null)
}

output "external_secrets_role_name" {
  description = "Name of the External Secrets Operator IRSA role (null if disabled)"
  value       = try(aws_iam_role.external_secrets[0].name, null)
}

output "load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IRSA role (null if disabled)"
  value       = try(aws_iam_role.aws_lb_controller[0].arn, null)
}

output "load_balancer_controller_role_name" {
  description = "Name of the AWS Load Balancer Controller IRSA role (null if disabled)"
  value       = try(aws_iam_role.aws_lb_controller[0].name, null)
}
