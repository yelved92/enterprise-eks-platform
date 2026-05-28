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

## Next: Phase 4 — GitOps with ArgoCD

