# Project State

**Current Phase:** Phase 6 — SSO Portal (Authentik + Kong OIDC) 🚧

## Completed Phases

| Phase | Summary | Status |
|---|---|---|
| 1 | Repo init, directory structure, .gitignore, README, ADRs | ✅ |
| 1.5 | Terraform backend bootstrap, Ansible scaffold, CI/CD scaffold, cost/upgrade/immutable docs | ✅ |
| 2 | Terraform base networking (VPC, 9 subnets, IGW, NAT, 5 SGs, 2 NACLs, KMS, IAM, 7 VPC endpoints) | ✅ Deployed |
| 3 | EKS cluster (1.34, private, KMS, t3.medium ×3, on-demand, IRSA, EBS CSI), after refactor (ADR-007, ADR-008) | ✅ Deployed & Validated |
| 4A | ArgoCD v2.8.3 deployed via Helm, 7 pods running, RBAC configured, Git repo registered | ✅ Deployed |
| 4B | TLS (cert-manager + Let's Encrypt), GitHub OAuth SSO, Kong NLB | ✅ Complete |
| 4C | OTel Demo deployed via Hybrid GitOps (18 pods), drift detection validated | ✅ Complete |
| 5A | Kyverno admission policies deployed (4 policies), ArgoCD app created | 🚧 Awaiting First Sync |
| 5B | Falco runtime security deployed via ArgoCD, modern eBPF, event detection confirmed | ✅ Deployed & Validated |
| 5C | External Secrets Operator deployed, AWS Secrets Manager integration | 🚧 Ready (no secrets created) |
| 5D | Network Policies created (default-deny + allow rules) | 🚧 Ready to Deploy |
| 6A | Route53 DNS records + cert-manager IRSA role for DNS-01 wildcard TLS | ✅ Applied |
| 6B | Authentik deployed via ArgoCD, Kong ingress at `auth.yelved.xyz` | ✅ Deployed |
| 6C | Authentik admin setup, OIDC provider created for ArgoCD | ✅ Complete |
| 6E | ArgoCD migrated from Dex to Authentik OIDC | ✅ Complete |

## Infrastructure Deployed (~140 resources)

| Category | Details |
|---|---|
| **Network** | 1 VPC, 9 subnets (3 public, 3 app, 3 data) across 3 AZs, IGW + 1 NAT, 7 route tables, 5 SGs, 2 NACLs, 7 VPC endpoints |
| **KMS** | 2 keys (default + EBS), auto-rotation, CloudWatch Logs + EC2 principals added |
| **IAM** | Cluster role, node role, VPC CNI IRSA, EBS CSI IRSA, cert-manager IRSA, External Secrets IRSA, AWS LB Controller IRSA (all least-privilege) |
| **EKS** | Cluster `dev`, K8s 1.34, private endpoint + restricted public (laptop IP), all logging, KMS-encrypted |
| **Nodes** | Managed node group, 3× t3.medium, on-demand, KMS-encrypted EBS, min 2 / max 6 |
| **Add-ons** | CoreDNS, kube-proxy, VPC-CNI, EBS CSI driver, AWS Load Balancer Controller (all with IRSA) |
| **LB Controller** | Custom IAM policy for ELBv2/EC2/WAF, IRSA role, subnet tags (`elbv2.k8s.aws/cluster`, `kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`) |
| **NLB** | Kong NLB switched to IP target mode (no NodePort exposure) |

## Cluster Validation
- `kubectl get nodes` → 3 Ready (2d21h uptime)
- All system pods running; IRSA role ARNs annotated on ServiceAccounts
- Laptop IP whitelisted for direct `kubectl` access

---

## Phase 4 — Detailed Sub-Step Plan (Revised)

### Phase 4A: Base ArgoCD Installation
- [x] **4.1** Deploy ArgoCD via Terraform Helm provider → `argocd` namespace
- [x] **4.2** Create ArgoCD project + bootstrap app-of-apps root Application
- [x] **4.3** Configure sync policies (auto-sync, self-heal, prune)
- [x] **4.4** Validate drift detection and reconciliation

### Phase 4B: TLS + OAuth (GitHub SSO) for ArgoCD UI
- [x] **4.5** Deploy cert-manager via ArgoCD GitOps (Helm chart + Let's Encrypt ClusterIssuer)
- [x] **4.6** Create Route53 DNS record for ArgoCD UI — **SKIPPED** (nip.io resolves automatically, no real domain)
- [x] **4.7** Configure ArgoCD LoadBalancer with TLS — **DONE** (nginx-ingress NLB + cert-manager TLS)
- [x] **4.8** Create GitHub OAuth App + configure ArgoCD Dex SSO
- [x] **4.9** Validate: GitHub login → ArgoCD UI → RBAC mapping

**Additional:**
- [x] **4.8b** Restricted login to `yelved-org` GitHub org — only org members can log in
- [x] **4.8c** Disabled admin password login — GitHub OAuth is the only auth method

### Phase 4C: GitOps Validation with Real Workload (Hybrid Approach)
- [x] **4.10** Deploy OpenTelemetry Demo via ArgoCD (first child app)
  - **Approach:** Hybrid (multi-source ArgoCD Application)
  - **Upstream source:** Official OpenTelemetry Demo Helm chart from Helm repo (pinned v0.32.0)
  - **Local source:** Custom `values.yaml` overrides in our repo (`apps/otel-demo/`)
  - **Status:** 18 pods Running, Synced + Healthy in ArgoCD UI
- [x] **4.11** Validate: app sync, health checks, drift detection
- [x] **4.12** Test manual change → drift → reconciliation cycle (scale self-healed ✅)

### Phase 4 Deliverables
- [x] ArgoCD running with OAuth (no admin password sharing)
- [x] cert-manager issuing trusted TLS certificates- [x] ArgoCD UI accessible via `https://argocd.3.224.67.220.nip.io`
- [x] OTel Demo deployed via Hybrid GitOps approach (upstream chart + local overrides)
- [x] GitOps workflow validated end-to-end (sync, health, drift detection)

---

## Phase5 — Detailed Sub-Step Plan

### Phase5A: Kyverno Admission Policies
- [x] **5.1** Update `argocd/projects/platform.yaml` with Kyverno Helm repo + CRDs
- [x] **5.2** Create `argocd/applications/kyverno.yaml` — multi-source ArgoCD app
- [x] **5.3** Create baseline Kyverno policies in `security/kyverno/policies/`:
  - [x] `disallow-privileged-containers.yaml`
  - [x] `require-non-root-users.yaml`
  - [x] `disallow-host-network-ports.yaml`
  - [x] `require-resource-limits.yaml`
- [ ] **5.4** Deploy Kyverno via ArgoCD sync (Unknown/Healthy — needs first sync)
- [ ] **5.5** Validate: privileged pod creation is denied

### Phase5B: Falco Runtime Security
- [x] **5.6** Update `argocd/projects/platform.yaml` with Falco Helm repo
- [x] **5.7** Create `argocd/applications/falco.yaml` — ArgoCD app
- [x] **5.8** Deploy Falco via ArgoCD sync — **DONE** (chart upgraded from 3.4.0 → 9.0.0 for modern_ebpf)
- [x] **5.9** Validate: Falco logs show runtime events — **CONFIRMED** (shell exec detected with modern BPF probe)

### Phase5C: External Secrets Operator
- [x] **5.10** Update `argocd/projects/platform.yaml` with ESO Helm repo
- [x] **5.11** Create `argocd/applications/external-secrets.yaml` — ArgoCD app
- [x] **5.12** Create `security/external-secrets/` with SecretStore + test ExternalSecret
- [x] **5.13** Deploy ESO via ArgoCD sync — **DONE** (operator running, idle)
- [ ] **5.14** Create test secret in AWS Secrets Manager
- [ ] **5.15** Validate: secret syncs to Kubernetes (`kubectl get secret test-secret -n test-secrets`)
- **Note:** ExternalSecret manifests were removed from Git. Operator is deployed but idle until AWS secrets are created.

### Phase5D: Network Policies + Pod Security Standards
- [x] **5.16** Create `security/network-policies/` with default-deny + allow rules
- [x] **5.17** Create `allow-core-dns.yaml`, `allow-argocd.yaml`, `allow-otel-demo.yaml`
- [ ] **5.18** Apply NetworkPolicies to namespaces
- [ ] **5.19** Enable Pod Security Standards (restricted) on namespaces
- [ ] **5.20** Test: pod-to-pod communication blocked between namespaces

### Phase5 Deliverables
- [ ] Kyverno enforcing admission policies (privileged, non-root, host restrictions, resource limits)
- [x] Falco detecting runtime threats (modern eBPF, logs to stdout) — **CONFIRMED**
- [ ] External Secrets Operator syncing AWS Secrets Manager secrets (idle — no secrets created)
- [ ] Network Policies isolating namespaces (default-deny + selective allow)
- [ ] Pod Security Standards enabled (restricted mode)

## Phase 6 — Detailed Sub-Step Plan

### Phase 6A: DNS + Wildcard TLS + IAM
- [x] **6.1** Add Route53 DNS records for auth, kong, grafana subdomains
- [x] **6.2** Add cert-manager IRSA role with Route53 DNS-01 permissions
- [x] **6.3** Terraform apply — deploy DNS records + IRSA role
- [x] **6.4** Update ClusterIssuer to use DNS-01 solver for wildcard certs
- [x] **6.5** Enable cert-manager serviceAccount annotation with IRSA role ARN

### Phase 6B: Deploy Authentik
- [x] **6.6** Create Helm chart for Authentik (`helm/authentik/`)
- [x] **6.7** Create ArgoCD Application for Authentik (`argocd/applications/authentik.yaml`)
- [x] **6.8** Create ExternalSecrets for Authentik secrets (deleted — no AWS secrets exist)
- [x] **6.9** Push + sync — Authentik deployed with Kong ingress at `auth.yelved.xyz`

### Phase 6C: Configure Authentik
- [x] **6.10** Configure GitHub OAuth source in Authentik (skipped — using local auth)
- [x] **6.11** Create OIDC providers + Applications for ArgoCD — **DONE**
- [ ] **6.12** Validate: `auth.yelved.xyz/if/user/` shows app library portal

### Phase 6D: Kong OIDC Plugin
- [ ] **6.13** Configure Kong OIDC plugin (openid-connect) pointing to Authentik
- [ ] **6.14** Create Kong Ingress routes for argocd, kong, grafana
- [ ] **6.15** Validate: unauthenticated requests redirected to Authentik login

### Phase 6E: Migrate ArgoCD
- [x] **6.16** Update ArgoCD OIDC config from Dex to Authentik — **DONE**
- [x] **6.17** Validate: ArgoCD login via Authentik — **CONFIRMED**
- [x] **6.18** Disable old Dex config — **DONE** (scaled to 0)

### Phase 6 Deliverables
- [x] Authentik running at `auth.yelved.xyz` with TLS
- [x] ArgoCD authenticating via Authentik (OIDC)
- [x] Kong NLB in IP target mode (no NodePort exposure)
- [x] HTTP → HTTPS redirect for all services
- [ ] App library portal at `auth.yelved.xyz/if/user/`
## Key Technical Debt
- Cluster SG attached to EKS instead of node SG (fix at Blue/Green)
- VPC endpoints cost ~$43/mo in dev (add per-endpoint flag)
- EKS add-on versions unpinned (set explicit defaults)
- `Environment = var.cluster_name` misnamed in tags
- No bastion for team access (not blocking — laptop IP works)

## Active ADRs
ADR-001 (Repo Structure) | ADR-002 (Session Continuity) | ADR-003 (Automation-First) | ADR-004 (Remote State) | ADR-005 (Blue/Green) | ADR-006 (Single Cluster First) | ADR-007 (Split IAM/IRSA) | ADR-008 (Version Pinning) | ADR-009 (Accepted — ArgoCD + OAuth via GitHub SSO with yelved-org restriction)

