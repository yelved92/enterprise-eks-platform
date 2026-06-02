# =============================================================================
# ArgoCD Module - Helm Deployment
# =============================================================================
# Deploys ArgoCD into the EKS cluster using the official Helm chart.
# Designed for internal cluster access (no public NLB) in Phase 4A.
# TLS/OAuth will be added in Phase 4B.
# -----------------------------------------------------------------------------

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "argocd"
      "istio-injection"              = "disabled" # ArgoCD ingress via NLB, not Istio
    }
  }
}

# ------------------------------------------------------------------------------
# ArgoCD Helm Release
# ------------------------------------------------------------------------------
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  version          = var.argocd_helm_version
  create_namespace = false # already created above
  timeout          = 600
  cleanup_on_fail  = true

  # Build the core YAML, optionally appending Dex config for GitHub OAuth
  values = [
    templatefile("${path.module}/values.yaml.tftpl", {
      domain        = var.argocd_domain != "" ? var.argocd_domain : "argocd.${var.cluster_name}.svc.cluster.local"
      ingress_class = "nginx"
      admin_user    = var.admin_user
      git_repo_url  = var.git_repo_url
      git_repo_name = var.git_repo_name
      oauth_enabled = var.oauth_enabled
      oauth_client_id     = var.oauth_client_id
      oauth_client_secret = var.oauth_client_secret
      oauth_org           = var.oauth_org
    })
  ]

  # Don't recreate if values change — allow in-place upgrade
  lifecycle {
    ignore_changes = [
      # Allow ArgoCD to manage its own ConfigMaps and Secrets
    ]
  }

  depends_on = [
    kubernetes_namespace_v1.argocd
  ]
}

# ------------------------------------------------------------------------------
# NLB hostname output — read the NLB DNS name after creation for reference
# ------------------------------------------------------------------------------
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = var.namespace
  }

  depends_on = [helm_release.argocd]
}

# ------------------------------------------------------------------------------
# Admin password — retrieved from the secret auto-created by the Helm chart
# The ArgoCD Helm chart creates argocd-initial-admin-secret automatically.
# ------------------------------------------------------------------------------