# Project State

**Current Phase:** Phase 4 — GitOps with ArgoCD + Secure Access (Planning)

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

---

## Phase 4 — Detailed Sub-Step Plan (Revised)

### Phase 4A: Base ArgoCD Installation
- [ ] **4.1** Deploy ArgoCD via Terraform Helm provider → `argocd` namespace
- [ ] **4.2** Create ArgoCD project + bootstrap app-of-apps root Application
- [ ] **4.3** Configure sync policies (auto-sync, self-heal, prune)
- [ ] **4.4** Validate drift detection and reconciliation

### Phase 4B: TLS + OAuth (GitHub SSO) for ArgoCD UI
- [ ] **4.5** Deploy cert-manager via Terraform/Helm (ClusterIssuer + Let's Encrypt)
- [ ] **4.6** Create Route53 DNS record for ArgoCD UI (e.g., argocd.yourdomain.com)
- [ ] **4.7** Configure ArgoCD LoadBalancer with TLS (NLB + cert-manager annotation)
- [ ] **4.8** Create GitHub OAuth App + configure ArgoCD Dex SSO
- [ ] **4.9** Validate: GitHub login → ArgoCD UI → RBAC mapping

### Phase 4C: GitOps Validation with Real Workload
- [ ] **4.10** Deploy OpenTelemetry Demo via ArgoCD (first child app)
- [ ] **4.11** Validate: app sync, health checks, ingress, drift detection
- [ ] **4.12** Test manual change → drift → reconciliation cycle

### Phase 4 Deliverables
- ArgoCD running with OAuth (no admin password sharing)
- cert-manager issuing trusted TLS certificates
- ArgoCD UI accessible via `https://argocd.yourdomain.com`
- OTel Demo deployed (accessible via kubectl port-forward or internal)
- GitOps workflow validated end-to-end

---

## Next Action
**Phase 4 — Start with Step 4.1: Deploy ArgoCD via Terraform Helm provider**
## Key Technical Debt
- Cluster SG attached to EKS instead of node SG (fix at Blue/Green)
- VPC endpoints cost ~$43/mo in dev (add per-endpoint flag)
- EKS add-on versions unpinned (set explicit defaults)
- `Environment = var.cluster_name` misnamed in tags
- No bastion for team access (not blocking — laptop IP works)

## Active ADRs
ADR-001 (Repo Structure) | ADR-002 (Session Continuity) | ADR-003 (Automation-First) | ADR-004 (Remote State) | ADR-005 (Blue/Green) | ADR-006 (Single Cluster First) | ADR-007 (Split IAM/IRSA) | ADR-008 (Version Pinning) | ADR-009 (Pending — ArgoCD + OAuth via GitHub SSO)

