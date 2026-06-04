# =============================================================================
# Route53 Module - Outputs
# =============================================================================

output "hosted_zone_id" {
  description = "The ID of the Route53 hosted zone"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "List of Route53 nameservers. Set these at your domain registrar."
  value       = aws_route53_zone.main.name_servers
}

output "argocd_record_fqdn" {
  description = "Fully qualified domain name for ArgoCD"
  value       = aws_route53_record.argocd.fqdn
}