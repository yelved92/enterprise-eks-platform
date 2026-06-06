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

#### Phase5B: Falco Runtime Security ✅
- [x] **5.6** Update `argocd/projects/platform.yaml` with Falco Helm repo
- [x] **5.7** Create `argocd/applications/falco.yaml`
- [x] **5.8** Deploy Falco via ArgoCD sync (chart upgraded 3.4.0 → 9.0.0 for modern_ebpf)
- [x] **5.9** Validate: Falco logs show runtime events (shell exec detected ✅)

#### Phase5C: External Secrets Operator
- [x] **5.10** Update `argocd/projects/platform.yaml` with ESO Helm repo
- [x] **5.11** Create `argocd/applications/external-secrets.yaml`
- [x] **5.12** Create `security/external-secrets/` config (deleted — no AWS secrets exist)
- [x] **5.13** Deploy ESO via ArgoCD sync (operator running, idle)
- [ ] **5.14** Create test secret in AWS Secrets Manager
- [ ] **5.15** Validate: secret syncs to Kubernetes

#### Phase5D: Network Policies + Pod Security Standards
- [x] **5.16** Create `security/network-policies/` manifests
- [x] **5.17** Create allow rules for core components
- [ ] **5.18** Apply NetworkPolicies to namespaces
- [ ] **5.19** Enable Pod Security Standards (restricted)
- [ ] **5.20** Test: pod-to-pod communication blocked

### Phase 6 — SSO Portal (Authentik + Kong OIDC) **[CURRENT 🚧]**

#### Phase 6A: DNS + Wildcard TLS + IAM ✅
- [x] **6.1** Add Route53 DNS records for auth, kong, grafana subdomains
- [x] **6.2** Add cert-manager IRSA role with Route53 DNS-01 permissions
- [x] **6.3** `terraform apply` — deploy DNS records + IRSA role
- [x] **6.4** Update ClusterIssuer to use DNS-01 solver for wildcard certs
- [x] **6.5** Enable cert-manager serviceAccount annotation with IRSA role ARN

#### Phase 6B: Deploy Authentik ✅
- [x] **6.6** Create Helm chart for Authentik
- [x] **6.7** Create ArgoCD Application for Authentik
- [x] **6.8** Create ExternalSecrets for Authentik (skipped — no AWS secrets)
- [x] **6.9** Push + sync — Authentik deployed at `auth.yelved.xyz`

#### Phase 6C: Configure Authentik 🚧
- [ ] **6.10** Configure GitHub OAuth source in Authentik (skipped — using local auth)
- [x] **6.11** Create OIDC providers + Applications for ArgoCD ✅
- [ ] **6.12** Validate: `auth.yelved.xyz/if/user/` shows app library portal

#### Phase 6D: Kong OIDC Plugin
- [ ] **6.13** Configure Kong OIDC plugin (openid-connect) pointing to Authentik
- [ ] **6.14** Create Kong Ingress routes for argocd, kong, grafana
- [ ] **6.15** Validate: unauthenticated requests redirected to Authentik login

#### Phase 6E: Migrate ArgoCD ✅
- [x] **6.16** Update ArgoCD OIDC config from Dex to Authentik
- [x] **6.17** Validate: ArgoCD login via Authentik
- [x] **6.18** Disable old Dex config

### Phase 7 — Service Mesh (Istio)
- [ ] Istio install, mTLS, ingress gateway, canary, circuit breaking, fault injection

### Phase 8 — Observability
- [ ] Prometheus, Grafana, Loki, Tempo, OpenTelemetry, AlertManager, dashboards, SLOs

## Medium Priority
- **Phase 9:** CI/CD pipelines (GitHub Actions — lint, scan, build, deploy, smoke tests)
- **Phase 10:** Disaster Recovery (Velero, EBS snapshots, failover, DR runbooks)
- **Phase 11:** Advanced topics (Chaos, Karpenter, Spot, Cosign, kube-bench, SRE playbooks)

## Technical Debt
- [ ] Fix `Environment = var.cluster_name` tag misnomer
- [ ] Pin EKS add-on versions explicitly
- [ ] Add per-endpoint flag for VPC endpoints (cost ~$43/mo)
- [ ] Strip EBS/EC2 volume permissions from node IAM role (use IRSA instead)
- [ ] Add prod environment directory stub
- [ ] Add `.tflint.hcl`, `.tfsec/`, `.checkov.yaml` baselines
- [ ] Cluster SG attached to EKS instead of node SG (fix at Blue/Green)
- [ ] No bastion for team access (not blocking — laptop IP whitelisted)
- [ ] Ansible ArgoCD playbook is outdated — manual Helm deploy used instead
- [ ] Fix `Secrets Manager` → `SecretsManager` typo (already done)

