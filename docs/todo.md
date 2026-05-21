# Project Task Management

## High Priority

### Phase 1: Project Initialization (Complete ✅)
- [x] Initialize Git repository
- [x] Create directory structure
- [x] Configure .gitignore
- [x] Create README.md
- [x] Create project-state.md
- [x] Create progress-log.md
- [x] Create architecture-decisions.md
- [x] Create todo.md
- [x] Initial commit
- [x] Push to GitHub
- [x] Updated prompt with automation, cost, and upgrade requirements

### Phase 1.5: Foundation Enhancements (Complete ✅)
- [x] Add Terraform backend configuration (S3 + DynamoDB locking)
- [x] Add Ansible directory structure with bootstrap playbooks
- [x] Add CI/CD pipeline scaffolding (GitHub Actions)
- [x] Add cost optimization strategy documentation
- [x] Add upgradeability strategy documentation
- [x] Add immutable infrastructure documentation

### Phase 2: Terraform Base Networking (Complete ✅)
- [x] Design VPC architecture (multi-AZ, public/private subnets)
- [x] Create Terraform root module structure
- [x] Implement VPC module
- [x] Implement subnet module
- [x] Implement Internet Gateway module
- [x] Implement NAT Gateway module
- [x] Implement route tables module
- [x] Implement security groups module
- [x] Implement Network ACLs module
- [x] Implement VPC endpoints module
- [x] Implement KMS module
- [x] Implement IAM base module
- [x] Create dev environment configuration
- [x] Create prod environment configuration
- [x] Terraform validation and plan
- [x] Documentation update

### Phase 3: EKS Cluster Deployment (Complete ✅)
- [x] Design EKS cluster architecture — ADR-006 (Single cluster first, Blue/Green later)
- [x] Implement EKS module (cluster + OIDC provider + CloudWatch logging)
- [x] Implement managed node groups module (t3.medium, on-demand, KMS encrypted)
- [x] Wire EKS module into dev environment main.tf
- [x] **Phase 3.5 Refactor pass** — see ADR-007 (split IAM/IRSA) & ADR-008 (version pinning)
  - [x] Create `terraform/modules/iam_irsa/` module (EBS CSI + VPC CNI IRSA roles)
  - [x] Fix broken `replace()` regex in EBS CSI trust policy
  - [x] Add `:aud` condition to IRSA trust policies
  - [x] Add `capacity_type` to node group (was missing — spot was a no-op)
  - [x] Remove reserved label `topology.kubernetes.io/zone`
  - [x] Remove conflicting `disk_size` from `aws_eks_node_group` (launch template owns it)
  - [x] Add `versions.tf` to env root + all 11 modules
  - [x] Remove unused `aws_partition` / `aws_caller_identity` data sources
- [x] Destroy original 104 resources (clean slate for refactored design)
- [x] `terraform apply` clean recreation (~120 resources) — SUCCESS
- [x] Validate cluster access — `aws eks update-kubeconfig` + `kubectl get nodes`
- [x] Verify IRSA wiring (`kubectl describe sa -n kube-system` shows role ARN)
- [x] Install EBS CSI driver add-on (`aws_eks_addon` with IRSA `service_account_role_arn`)
- [x] Validate private endpoint posture (no public access; VPC endpoint traffic)
- [x] KMS key policy fixes — CloudWatch Logs + EC2 service principals added
- [x] SG egress rules fixed — `from_port = -1` → `0`
- [x] Documentation update — Phase 3 complete

### Phase 4: GitOps with ArgoCD
- [ ] Design ArgoCD architecture (app-of-apps)
- [ ] Install ArgoCD via Helm
- [ ] Configure ArgoCD projects
- [ ] Create bootstrap application
- [ ] Configure repository connection
- [ ] Implement app-of-apps pattern
- [ ] Configure sync policies
- [ ] Validate drift detection
- [ ] Documentation update

## Medium Priority

### Phase 5: Security Hardening
- [ ] Install Kyverno / OPA Gatekeeper
- [ ] Define admission policies
- [ ] Install Falco for runtime security
- [ ] Configure Trivy for image scanning
- [ ] Deploy External Secrets Operator
- [ ] Configure AWS Secrets Manager integration
- [ ] Implement network policies
- [ ] Implement pod security standards
- [ ] Validate security controls
- [ ] Documentation update

### Phase 6: Service Mesh (Istio)
- [ ] Install Istio via Helm
- [ ] Configure mTLS
- [ ] Deploy ingress gateway
- [ ] Configure traffic shifting
- [ ] Implement canary deployments
- [ ] Configure circuit breaking
- [ ] Configure retries
- [ ] Implement fault injection
- [ ] Validate mTLS
- [ ] Documentation update

### Phase 7: Observability Stack
- [ ] Install Prometheus
- [ ] Install Grafana
- [ ] Install Loki
- [ ] Install Tempo
- [ ] Install OpenTelemetry
- [ ] Configure AlertManager
- [ ] Create dashboards
- [ ] Configure alerts
- [ ] Define SLO/SLIs
- [ ] Validate observability
- [ ] Documentation update

### Phase 8: Application Deployment (OpenTelemetry Demo)
- [ ] Design application deployment strategy
- [ ] Configure Helm chart for demo app
- [ ] Deploy via ArgoCD
- [ ] Configure ingress
- [ ] Enable tracing
- [ ] Enable autoscaling
- [ ] Validate application
- [ ] Documentation update

## Nice to Have

### Phase 9: CI/CD Pipelines
- [ ] Design pipeline structure
- [ ] Implement linting stage
- [ ] Implement Terraform validation
- [ ] Implement security scanning
- [ ] Implement container scanning
- [ ] Implement policy validation
- [ ] Implement build & test
- [ ] Implement deploy stage
- [ ] Implement GitOps sync
- [ ] Implement smoke tests
- [ ] Documentation update

### Phase 10: Disaster Recovery
- [ ] Install Velero
- [ ] Configure EBS snapshots
- [ ] Define restore procedures
- [ ] Implement cluster failover workflow
- [ ] Configure Route53 failover
- [ ] Validate backup/restore
- [ ] Create DR runbooks
- [ ] Documentation update

### Phase 11: Advanced Topics
- [ ] Chaos engineering experiments
- [ ] Karpenter advanced configuration
- [ ] Spot interruption handling
- [ ] FinOps / cost optimization
- [ ] Cluster upgrade strategy
- [ ] Multi-account AWS strategy
- [ ] WAF integration
- [ ] DDoS protection
- [ ] eBPF observability
- [ ] kube-bench scanning
- [ ] kube-hunter scanning
- [ ] Supply chain security / SBOM
- [ ] Image signing with Cosign
- [ ] SRE operational playbooks
- [ ] Incident response simulations
- [ ] SLO-driven alerting

## Blockers
- None currently

## Technical Debt
*Tracked from code review on 2026-05-20. Items not addressed in the Phase 3.5 refactor are queued here for later phases where they become natural fits.*

### High value, deferred to natural integration points
- **No bastion / VPN for private EKS endpoint** — currently no way to reach `kubectl` from a workstation. Add an SSM-only EC2 bastion module (no SSH, no key pair, IMDSv2 required) or AWS Client VPN. Decide before Phase 4 (GitOps) since ArgoCD setup needs API access.
- **Cluster SG attached to EKS instead of node SG** — the `vpc_config.security_group_ids` should reference the node SG, not the (mostly empty) cluster SG. Plan to address during Blue/Green refactor where SG wiring will be re-thought.
- **VPC endpoints sharing cluster SG** — should have a dedicated `vpc-endpoints` SG that ingresses 443 from the node SG. Same window as above.
- **Add modern `access_config` block on `aws_eks_cluster`** — prefer `authentication_mode = "API"` + `aws_eks_access_entry` over the legacy `aws-auth` ConfigMap. Add `bootstrap_self_managed_addons = false`. Apply during a planned cluster recreation, not in-place.
- **Pin EKS add-on versions** — currently `null` (latest). Set explicit defaults per cluster version (e.g., for 1.30: `coredns v1.11.3-eksbuild.1`, `kube-proxy v1.30.3-eksbuild.5`, `vpc-cni v1.18.3-eksbuild.2`); use `data "aws_eks_addon_version"` for resolution.
- **Strip EBS/EC2 volume permissions from node IAM role** — these duplicated the EBS CSI role's permissions. Remove after EBS CSI IRSA is validated to be working in cluster.
- **`prod` environment directory missing** — todo.md previously claimed it was done. Either create stub `terraform/environments/prod/` or correct the doc (already corrected in project-state.md).

### Cost / FinOps
- **All 7 VPC interface endpoints enabled in dev** (~$0.01/hr * 6 * 24 * 30 ≈ $43/mo) — inconsistent with cost-optimized intent. Add per-endpoint flag in `tfvars` and document the cost/security tradeoff.

### Hygiene
- **`Environment = var.cluster_name` misnomer** in all module tags — will break cost-allocation reports once Blue/Green clusters exist (`dev-blue` vs `dev-green` both tagged as Environment). Refactor to accept an `environment` variable separately from `cluster_name`.
- **Duplicate tagging**: `default_tags` in provider + per-module `merge()` tagging adds noise. Pick one strategy.
- **`ignore_changes = [scaling_config[0].desired_size]`** is correct for an autoscaler-managed cluster but premature (no Karpenter/CA yet). Gate behind a variable.
- **Encoding artifacts in `progress-log.md`** — `�` characters from a Windows cp1252 source. Re-save as UTF-8 (partially fixed during Session 6).
- **No `tflint` / `tfsec` / `checkov` config files** — CI workflows exist but configs don't, so noise drowns signal. Add `.tflint.hcl`, `.tfsec/`, `.checkov.yaml` baselines.

## Future Improvements
- Multi-region deployment
- Cross-account IAM roles
- Service catalog for developer self-service
- Internal developer platform (IDP)
- Backstage integration

