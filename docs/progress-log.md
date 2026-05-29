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

## Next: Phase 4A — Step 4.2: Create ArgoCD project + bootstrap app-of-apps

