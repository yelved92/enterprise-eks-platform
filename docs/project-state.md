# Project State: Enterprise-Grade AWS EKS Platform

## Current Phase

**Phase 3: EKS Cluster Deployment** *(In Progress — Refactor pass complete, awaiting clean apply)*

## Completed Components
- [x] Repository initialized
- [x] Directory structure created
- [x] .gitignore configured
- [x] README.md created
- [x] project-state.md created
- [x] progress-log.md created
- [x] architecture-decisions.md created
- [x] todo.md created
- [x] Initial commit
- [x] Pushed to GitHub (https://github.com/yelved92/enterprise-eks-platform)
- [x] Updated project prompt with automation, cost, and upgrade requirements
- [x] Added ADR-003 (Automation-First), ADR-004 (Remote State), ADR-005 (Blue/Green Clusters)
- [x] Added ADR-006 (Single cluster first), ADR-007 (Split IAM/IRSA), ADR-008 (Version Pinning)
- [x] Phase 1.5: Foundation Enhancements - Complete
- [x] **Phase 2: Terraform Base Networking - Deployed**
  - [x] VPC module - 1 VPC (vpc-0aba77aa632193ef3) with DNS support
  - [x] Subnets module - 9 subnets across 3 AZs (3 public, 3 app, 3 data)
  - [x] Gateways module - 1 IGW + 1 NAT Gateway (single, cost-optimized)
  - [x] Routing module - 7 route tables + 9 associations + 7 routes
  - [x] Security Groups module - 5 security groups (ALB, Cluster, Nodes, Internal, Data)
  - [x] Network ACLs module - 2 NACLs (public + private) with stateless rules
  - [x] KMS module - 2 KMS keys (default + EBS) with automatic rotation
  - [x] IAM module - 2 roles (cluster + node) with attached policies
  - [x] VPC Endpoints module - 7 endpoints (S3, DynamoDB, ECR, SSM, KMS, Logs, STS)
  - [x] Dev environment root configuration - All modules wired and applied
  - [x] Dev terraform.tfvars - Explicit variables per production practice
  - [x] Dev backend.tf - S3 remote state + DynamoDB locking (verified working)

## Pending Tasks
- [ ] **CURRENT PHASE:** Phase 3 - EKS Cluster Deployment
  - [x] Design EKS cluster architecture — ADR-006: Single cluster first, Blue/Green later
  - [x] Implement EKS module (cluster + OIDC provider + CloudWatch logging)
  - [x] Implement managed node groups module
  - [x] Code review of all Phase 2 + Phase 3 modules (24 findings documented)
  - [x] Refactor pass: split `iam_irsa` module, fix IRSA trust policy, add `capacity_type`, remove reserved label, add `versions.tf` everywhere
  - [x] Destroy original 104 resources (clean slate before applying refactored design)
  - [ ] **NEXT:** `terraform apply` clean recreation (~120 resources)
  - [ ] Validate cluster access — kubectl, node readiness, pod scheduling
  - [ ] Install EBS CSI driver add-on (via aws_eks_addon + IRSA)
  - [ ] Implement Karpenter module (post-GitOps, post-application)
  - [ ] Documentation update — Phase 3 complete

## Infrastructure Deployed
- **None currently.** All previous resources were intentionally destroyed in preparation for a clean apply of the refactored design.
- Previous deployment (now destroyed): 104 networking/IAM/KMS resources in us-east-1, no EKS cluster ever applied.
- Next apply target: ~120 resources (networking + EKS cluster + node group + IRSA roles + add-ons).

## Refactor Summary (Phase 3.5)

The following design improvements were applied **before** the EKS cluster was ever created in AWS, making them effectively free changes:

| Change | Reason | ADR |
|---|---|---|
| Split `iam` into `iam` + `iam_irsa` modules | Resolved "count depends on unknown" error; clean separation of base IAM from OIDC-dependent IRSA roles | ADR-007 |
| Fixed broken `replace()` regex in EBS CSI trust policy | Original pattern `"/^.*oidc-provider//"` was malformed; would have silently produced an incorrect IRSA condition key | ADR-007 |
| Added `:aud = "sts.amazonaws.com"` IRSA condition | Required by AWS IRSA spec; prevents cross-cluster token reuse | ADR-007 |
| Added `capacity_type = var.use_spot ? "SPOT" : "ON_DEMAND"` | Previous `use_spot` only set a label; nodes were always on-demand regardless | Code review #11 |
| Removed `topology.kubernetes.io/zone = "multi-az"` label | Reserved Kubernetes label; auto-set by kubelet; overriding breaks topology-aware scheduling | Code review #10 |
| Removed `disk_size` from `aws_eks_node_group` resource | Conflicts with launch template's `block_device_mappings` (EKS API rejects both) | Code review |
| Added VPC CNI IRSA role in `iam_irsa` | Moves CNI permissions off the node instance profile to ServiceAccount-scoped role | Code review #8 |
| Added `versions.tf` to env root + all 11 modules | Reproducibility; pins Terraform CLI and provider majors | ADR-008 |
| Removed unused `aws_partition` / `aws_caller_identity` data sources | Dead code in `eks` and `managed_node_groups` modules | Code review #17 |

## Validation Status
- `terraform validate` — passes
- `terraform init` — succeeds with new version constraints; reuses locked providers
- `terraform plan` — clean: 12 to add (EKS cluster, OIDC provider, log group, 3 add-ons, node group, launch template, 2 IRSA roles, 2 policy attachments) **on top of** the 108 networking resources to be recreated
- AWS state — zero resources tagged with `Project=enterprise-eks-platform` (verified via `aws ec2 describe-vpcs`)
- Terraform state — 0 resources (verified via `terraform state list`)

## Known Issues
- None blocking. Ready for clean apply.

## Security Decisions
- Security groups with least-privilege defaults
- NACLs provide stateless subnet filtering
- VPC endpoints enable private AWS service access (no internet exposure)
- KMS keys with automatic rotation for encryption
- No SSH access to nodes (private subnets)
- VPC Flow Logs disabled by default in dev (cost optimization)
- Single NAT Gateway for dev to minimize costs (~$32/month vs ~$96/month for 3 AZs)
- **IRSA trust policies now enforce both `:sub` and `:aud` conditions** (ADR-007)
- **Provider versions pinned at module and environment level** (ADR-008)
- **Modern S3-native lockfile** in use (no DynamoDB lock table needed)




