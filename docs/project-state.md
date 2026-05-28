# Project State

**Current Phase:** Phase 4 — GitOps with ArgoCD (Ready)

## Completed Phases

| Phase | Summary | Status |
|---|---|---|
| 1 | Repo init, directory structure, .gitignore, README, ADRs | ✅ |
| 1.5 | Terraform backend bootstrap, Ansible scaffold, CI/CD scaffold, cost/upgrade/immutable docs | ✅ |
| 2 | Terraform base networking (VPC, 9 subnets, IGW, NAT, 5 SGs, 2 NACLs, KMS, IAM, 7 VPC endpoints) | ✅ Deployed |
| 3 | EKS cluster (1.30, private, KMS, t3.medium ×3, on-demand, IRSA, EBS CSI), after refactor (ADR-007, ADR-008) | ✅ Deployed & Validated |

## Infrastructure Deployed (~120 resources)

| Category | Details |
|---|---|
| **Network** | 1 VPC, 9 subnets (3 public, 3 app, 3 data) across 3 AZs, IGW + 1 NAT, 7 route tables, 5 SGs, 2 NACLs, 7 VPC endpoints |
| **KMS** | 2 keys (default + EBS), auto-rotation, CloudWatch Logs + EC2 principals added |
| **IAM** | Cluster role, node role, VPC CNI IRSA, EBS CSI IRSA (all least-privilege) |
| **EKS** | Cluster `dev`, K8s 1.30, private endpoint + restricted public (laptop IP), all logging, KMS-encrypted |
| **Nodes** | Managed node group, 3× t3.medium, on-demand, KMS-encrypted EBS, min 2 / max 6 |
| **Add-ons** | CoreDNS, kube-proxy, VPC-CNI, EBS CSI driver (all with IRSA) |

## Cluster Validation
- `kubectl get nodes` → 3 Ready (2d21h uptime)
- All system pods running; IRSA role ARNs annotated on ServiceAccounts
- Laptop IP whitelisted for direct `kubectl` access

## Next Action
**Phase 4 — Install ArgoCD via Terraform Helm provider (planned, not yet started)**

## Key Technical Debt
- Cluster SG attached to EKS instead of node SG (fix at Blue/Green)
- VPC endpoints cost ~$43/mo in dev (add per-endpoint flag)
- EKS add-on versions unpinned (set explicit defaults)
- `Environment = var.cluster_name` misnamed in tags
- No bastion for team access (not blocking — laptop IP works)

## Active ADRs
ADR-001 (Repo Structure) | ADR-002 (Session Continuity) | ADR-003 (Automation-First) | ADR-004 (Remote State) | ADR-005 (Blue/Green) | ADR-006 (Single Cluster First) | ADR-007 (Split IAM/IRSA) | ADR-008 (Version Pinning)

