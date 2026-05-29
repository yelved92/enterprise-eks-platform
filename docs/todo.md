# Todo
## High Priority

### Phase 4 — GitOps with ArgoCD **[NEXT]**
- [x] Install ArgoCD via Terraform Helm provider → `argocd` namespace
- [ ] Configure GitHub repo connection (deploy key or PAT)
- [ ] Create ArgoCD project + bootstrap app
- [ ] Implement app-of-apps pattern (root → child apps)
- [ ] Configure sync policies (auto-sync, self-heal, prune)
- [ ] Validate drift detection and reconciliation

### Phase 5 — Security Hardening
- [ ] Kyverno / OPA Gatekeeper admission policies
- [ ] Falco runtime security, Trivy image scanning
- [ ] External Secrets Operator + AWS Secrets Manager
- [ ] Network policies, Pod Security Standards

### Phase 6 — Service Mesh (Istio)
- [ ] Istio install, mTLS, ingress gateway, canary, circuit breaking, fault injection

### Phase 7 — Observability
- [ ] Prometheus, Grafana, Loki, Tempo, OpenTelemetry, AlertManager, dashboards, SLOs

# Todo
## High Priority

### Phase 4 — GitOps with ArgoCD + Secure Access + OTel Demo **[NEXT]**

#### Phase 4A: Base ArgoCD Installation
- [x] **4.1** Deploy ArgoCD via Terraform Helm provider → `argocd` namespace
- [x] **4.2** Create ArgoCD project + bootstrap app-of-apps root Application
- [x] **4.3** Configure sync policies (auto-sync, self-heal, prune)
- [x] **4.4** Validate drift detection and reconciliation

#### Phase 4B: TLS + OAuth (GitHub SSO) for ArgoCD UI
- [x] **4.5** Deploy cert-manager via ArgoCD GitOps (Helm chart + Let's Encrypt ClusterIssuer)
- [ ] **4.6** Create Route53 DNS record for ArgoCD UI (e.g., argocd.yourdomain.com)
- [ ] **4.7** Configure ArgoCD LoadBalancer with TLS (NLB + cert-manager annotation)
- [ ] **4.8** Create GitHub OAuth App + configure ArgoCD Dex SSO
- [ ] **4.9** Validate: GitHub login → ArgoCD UI → RBAC mapping

#### Phase 4C: GitOps Validation with Real Workload
- [ ] **4.10** Deploy OpenTelemetry Demo via ArgoCD (first child app)
- [ ] **4.11** Validate: app sync, health checks, ingress, drift detection
- [ ] **4.12** Test manual change → drift → reconciliation cycle

### Phase 5 — Security Hardening
- [ ] Kyverno / OPA Gatekeeper admission policies
- [ ] Falco runtime security, Trivy image scanning
- [ ] External Secrets Operator + AWS Secrets Manager
- [ ] Network policies, Pod Security Standards

### Phase 6 — Service Mesh (Istio)
- [ ] Istio install, mTLS, ingress gateway, canary, circuit breaking, fault injection

### Phase 7 — Observability
- [ ] Prometheus, Grafana, Loki, Tempo, OpenTelemetry, AlertManager, dashboards, SLOs

## Medium Priority
- **Phase 8:** CI/CD pipelines (GitHub Actions — lint, scan, build, deploy, smoke tests)
- **Phase 9:** Disaster Recovery (Velero, EBS snapshots, failover, DR runbooks)
- **Phase 10:** Advanced topics (Chaos, Karpenter, Spot, Cosign, kube-bench, SRE playbooks)

## Technical Debt
- [ ] Fix `Environment = var.cluster_name` tag misnomer
- [ ] Pin EKS add-on versions explicitly
- [ ] Add per-endpoint flag for VPC endpoints (cost ~$43/mo)
- [ ] Strip EBS/EC2 volume permissions from node IAM role (use IRSA instead)
- [ ] Add prod environment directory stub
- [ ] Add `.tflint.hcl`, `.tfsec/`, `.checkov.yaml` baselines
- [ ] Cluster SG attached to EKS instead of node SG (fix at Blue/Green)
- [ ] No bastion for team access (not blocking — laptop IP whitelisted)

