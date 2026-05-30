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

  values = [
    # Core values — NLB + ingress enabled when argocd_domain is set
    <<-EOT
    # --------------------------------------------------------------------------
    # Global settings
    # --------------------------------------------------------------------------
    global:
      domain: ${var.argocd_domain != "" ? var.argocd_domain : "argocd.${var.cluster_name}.svc.cluster.local"}

    # --------------------------------------------------------------------------
    # Server (ArgoCD API + UI)
    # --------------------------------------------------------------------------
    server:
      service:
        type: ClusterIP
        port: 443

      # Ingress enabled when domain is set — routed through nginx-ingress
      ingress:
        enabled: ${var.argocd_domain != "" ? true : false}
        annotations:
          cert-manager.io/cluster-issuer: letsencrypt-prod
          kubernetes.io/tls-acme: "true"
        labels: {}
        ingressClassName: nginx
        hosts:
          - ${var.argocd_domain}
        tls:
          - hosts:
              - ${var.argocd_domain}
            secretName: argocd-server-tls

      # RBAC via configmap (no SSO yet)
      rbacConfig:
        policy.default: role:readonly
        policy.csv: |
          p, role:admin, applications, *, */*, allow
          p, role:admin, clusters, *, *, allow
          p, role:admin, projects, *, *, allow
          g, ${var.admin_user}, role:admin

    # --------------------------------------------------------------------------
    # Config Management Plugins (Helm, Kustomize)
    # --------------------------------------------------------------------------
    configs:
      params:
        server.insecure: true      # TLS termination handled externally
        server.disable.auth: false  # Auth required

      # Repository connection — managed via Terraform variable
      repositories:
        - url: ${var.git_repo_url}
          type: git
          name: ${var.git_repo_name}

    # --------------------------------------------------------------------------
    # Controller settings
    # --------------------------------------------------------------------------
    controller:
      replicas: 1
      logLevel: info
      appSync:
        # Default sync interval (3 min for drift detection)
        sync_interval: 180

    # --------------------------------------------------------------------------
    # Repo server
    # --------------------------------------------------------------------------
    repoServer:
      replicas: 1
      autoscaling:
        enabled: false
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 256Mi

    # --------------------------------------------------------------------------
    # Redis
    # --------------------------------------------------------------------------
    redis:
      enabled: true
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 200m
          memory: 128Mi

    # --------------------------------------------------------------------------
    # Application controller
    # --------------------------------------------------------------------------
    applicationController:
      replicas: 1
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
    EOT
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