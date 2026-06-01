# Progress Log

## 2026-05-12 — Phase 1: Init
- Repo initialized, dir structure, .gitignore, README, ADRs, state docs
- Push to GitHub (`yelved92/enterprise-eks-platform`)

## 2026-05-12 — Phase 1.5: Foundation
- Terraform backend bootstrap (S3 + DynamoDB), Ansible scaffold, CI/CD (GitHub Actions)
- Docs: cost-optimization, upgradeability, immutable-infrastructure

## 2026-05-13 — Phase 2: Base Networking
- 9 Terraform modules, 104 resources deployed across 3 AZs
- VPC, subnets, gateways, routing, SGs, NACLs, KMS, IAM, VPC endpoints

## 2026-05-13 — Phase 3 Design
- ADR-006: Single cluster first, Blue/Green later
- EKS module + managed node groups module designed

## 2026-05-13 — Session 5: EKS Modules Wired
- EKS + node group modules wired into dev env, plan validated (8 to add)

## 2026-05-20 — Session 6: Code Review & Refactor ✅
- **24 findings** across Phase 2 & 3 modules. Critical fixes before any EKS resources existed:
  - Split IAM → `iam` + `iam_irsa` (ADR-007) — fixed count-on-unknown error
  - Fixed broken `replace()` regex in EBS CSI trust policy (silent mis-auth risk)
  - Added `:aud` condition to IRSA trust policies (cross-cluster token protection)
  - Added `capacity_type` to node group (spot was a no-op label before)
  - Removed reserved `topology.kubernetes.io/zone` label
  - Removed conflicting `disk_size` (launch template collision)
  - Added `versions.tf` to all modules + env root (ADR-008)
- Destroyed 104 resources for clean slate

## 2026-05-21 — Session 7: EKS Cluster Deployed ✅
- `terraform apply` — ~120 resources created in ~22 min
- **Live fixes during apply:**
  - KMS key policy: added CloudWatch Logs + EC2 service principals (both caused failures)
  - SG egress: `from_port = -1 → 0` (AWS provider v6 normalization)
- Validation: 3 nodes Ready, all system pods running, IRSA working, private endpoint confirmed
- Laptop IP whitelisted for `kubectl` access

## 2026-05-27 — Session 8: Phase 4 Planning & Architecture Decisions ✅
- Revised Phase 4 plan to include three sub-phases:
  - **4A:** Base ArgoCD installation via Terraform Helm provider
  - **4B:** TLS (cert-manager + Let's Encrypt) + GitHub OAuth SSO for ArgoCD UI
  - **4C:** GitOps validation with OpenTelemetry Demo as first workload
- **Key decisions made:**
  - ArgoCD exposed via public NLB with TLS + GitHub OAuth (not local admin password)
  - cert-manager deployed in Phase 4B (not Phase 5) — it's infrastructure for HTTPS, not a security policy
  - OTel Demo deployed right after ArgoCD (not delayed until Phase 8) — validates GitOps with real workload
  - Ansible used later for DR, upgrades, chaos testing — not for current phases
  - Night destroy/apply cycle viable for cost savings (~$120/mo), deferred until platform is stable
- Cost analysis reviewed: ~$152/mo current, biggest drivers EKS control plane ($92) + NAT ($32)
- Updated project-state.md with revised Phase 4 sub-steps
- Updated todo.md with refined Phase 4 breakdown

## 2026-05-28 — Session 9: Phase 4A — ArgoCD Deployed ✅
- **Live fixes during apply:**
  - Fixed stray `"` quotes in `argocd/versions.tf`, `outputs.tf`, `variables.tf` (caused plan error)
  - Fixed `repositories: |` → `repositories:` (Helm template can't iterate a string)
  - Removed duplicate `random_password` + `kubernetes_secret_v1` (Helm chart auto-creates admin secret)
  - Removed stray `EOT` at end of `main.tf`
- EKS cluster upgraded **1.33 → 1.34** alongside ArgoCD deployment
- ArgoCD v2.8.3 (Helm chart 5.46.0) deployed into `argocd` namespace
- 7 pods running: application-controller, applicationset-controller, dex-server, notifications, redis, repo-server, server
- RBAC configured: `yelved92` mapped as admin, default role: readonly
- Git repo registered: `https://github.com/yelved92/enterprise-eks-platform.git`
- Admin password retrieved from auto-created secret via `kubectl`
- UI confirmed accessible via `kubectl port-forward svc/argocd-server 9090:80`
- **Step 4.2:** Created `AppProject/platform` + `Application/bootstrap` (app-of-apps root)
- **Step 4.3/4.4:** Sync policies (prune, selfHeal, allowEmpty) already configured on bootstrap app
- Fixed stray `"` quotes in `argocd/applications/bootstrap.yaml`, `platform-apps.yaml`

## 2026-05-28 — Session 10: Phase 4B — cert-manager via ArgoCD GitOps ✅
- **Architecture decision:** cert-manager deployed via ArgoCD (not Terraform) — cluster add-ons belong in GitOps
- Created multi-source ArgoCD Application for cert-manager (upstream Helm chart + local ClusterIssuer)
- Updated `AppProject/platform` with:
  - Jetstack Helm repo (`https://charts.jetstack.io`)
  - `kube-system` namespace (for cert-manager leader election)
  - cert-manager CRDs (ClusterIssuer, Issuer, Certificate, Challenge, Order)
- Let's Encrypt ClusterIssuer created (`letsencrypt-prod`, email: yelved92@gmail.com)
- cert-manager v1.14.5 running: cert-manager, cainjector, webhook (3 pods)
- Fixed `admin@example.com` → `yelved92@gmail.com` (Let's Encrypt rejects example.com)
- **Live fixes:** project `sourceRepos`, `destinations`, `clusterResourceWhitelist` all iteratively updated

## 2026-05-30 — Session 11: Phase 4B Complete — GitHub OAuth SSO + Org Restriction ✅
- **Steps 4.6/4.7 (NLB + TLS):** Already working from prior session — nginx-ingress NLB + cert-manager TLS confirmed
- **Step 4.8 (GitHub OAuth):** Full Dex SSO implementation:
  - Created GitHub OAuth App `Ov23ctOhGXMVhcioRbt8`
  - Added OAuth variables to ArgoCD Terraform module (`oauth_enabled`, `client_id`, `client_secret`, `org`)
  - Refactored Helm values from inline to `templatefile()` approach for cleaner conditional Dex config
  - Fixed `dex.config` YAML path — goes under `configs.cm.dex.config` in the Helm chart
  - Dex confirmed running with "config connector: github" in logs
- **Org restriction:** Created `yelved-org` GitHub org, restricted Dex to only org members
- **Admin disabled:** Set `admin.enabled: false` — GitHub OAuth is the only login method
- **RBAC:** `yelved92` mapped to admin, all others read-only
- **Security hardening:** Attempted `loadBalancerSourceRanges` but chart doesn't render it; left `preserve_client_ip.enabled=true` as improvement
- Git history cleaned (squashed commits with IP references)

## 2026-06-01 — Session 12: Phase 4C — OTel Demo App Definition Created ✅
- **Architecture decision:** Switched from git-based upstream (`github.com/open-telemetry/opentelemetry-demo.git`) to official Helm repo (`https://open-telemetry.github.io/opentelemetry-helm-charts`) with chart `opentelemetry-demo` pinned to 0.32.0
- **Multi-source pattern:** Uses `$values` ref pattern — Helm chart from repo, values from our git repo
- **`argocd/projects/platform.yaml`:** Added OTel Helm repo to `sourceRepos`
- **`argocd/applications/otel-demo.yaml`:** Rewrote to use Helm repo + `$values/apps/otel-demo/values.yaml`
- **`apps/otel-demo/values.yaml`:** Refreshed with proper upstream schema — per-service resource limits, only core services enabled, optional components (loadGenerator, kafka, flagd) disabled for lean dev deployment
- Namespace fixed to `opentelemetry-demo`
- **Files ready for commit to `feat/phase-4-argocd`** — waiting for user to push and sync

## Next: Phase 4C — Steps 4.11-4.12: Validate sync, health, drift detection

