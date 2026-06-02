# =============================================================================
# ArgoCD Module - Outputs
# =============================================================================

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "argocd_helm_release_name" {
  description = "Name of the Helm release for ArgoCD"
  value       = helm_release.argocd.name
}

output "argocd_helm_version" {
  description = "Version of the deployed ArgoCD Helm chart"
  value       = helm_release.argocd.version
}

output "argocd_server_service" {
  description = "Name of the ArgoCD server service (for port-forward/svc dns)"
  value       = "argocd-server"
}

output "argocd_admin_password_command" {
  description = "Command to retrieve the initial admin password from the auto-created secret"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_nlb_hostname" {
  description = "NLB DNS hostname for ArgoCD (use this with nip.io)"
  value       = var.argocd_domain != "" ? var.argocd_domain : try(data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname, null)
}
