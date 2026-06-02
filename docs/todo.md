# Todo
## High Priority

### Phase 4 — GitOps with ArgoCD + Secure Access + OTel Demo **[COMPLETE ✅]**
- [x] **4.1-4.4** Base ArgoCD Installation + validation
- [x] **4.5-4.9** TLS + OAuth (GitHub SSO) for ArgoCD UI
- [x] **4.10-4.12** OTel Demo deployed via Hybrid GitOps + drift detection validated

### Phase 5 — Security Hardening **[CURRENT 🚧]**

#### Phase5A: Kyverno Admission Policies
- [x] **5.1** Update `argocd/projects/platform.yaml` with Kyverno Helm repo + CRDs
- [x] **5.2** Create `argocd/applications/kyverno.yaml`
- [x] **5.3** Create baseline Kyverno policies (4 policies)
- [ ] **5.4** Deploy Kyverno via ArgoCD sync
- [ ] **5.5** Validate: privileged pod creation is denied

#### Phase5B: Falco Runtime Security
- [x] **5.6** Update `argocd/projects/platform.yaml` with Falco Helm repo
- [x] **5.7** Create `argocd/applications/falco.yaml`
- [ ] **5.8** Deploy Falco via ArgoCD sync
- [ ] **5.9** Validate: Falco logs show runtime events

#### Phase5C: External Secrets Operator
- [x] **5.10** Update `argocd/projects/platform.yaml` with ESO Helm repo
- [x] **5.11** Create `argocd/applications/external-secrets.yaml`
- [x] **5.12** Create `security/external-secrets/` config
- [ ] **5.13** Deploy ESO via ArgoCD sync
- [ ] **5.14** Create test secret in AWS Secrets Manager
- [ ] **5.15** Validate: secret syncs to Kubernetes

#### Phase5D: Network Policies + Pod Security Standards
- [x] **5.16** Create `security/network-policies/` manifests
- [x] **5.17** Create allow rules for core components
- [ ] **5.18** Apply NetworkPolicies to namespaces
- [ ] **5.19** Enable Pod Security Standards (restricted)
- [ ] **5.20** Test: pod-to-pod communication blocked

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

#### Phase 4C: GitOps Validation with Real Workload (Hybrid Approach)
- [ ] **4.10** Deploy OpenTelemetry Demo via ArgoCD (first child app)
  - **Approach:** Hybrid (multi-source ArgoCD Application)
  - **Upstream source:** Official OpenTelemetry Demo Helm chart (`https://github.com/open-telemetry/opentelemetry-demo.git`)
  - **Local source:** Custom `values.yaml` overrides in our repo (`apps/otel-demo/`)
  - **Benefits:** Version-controlled customizations, can pin upstream versions, true GitOps
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

