# Todo
## High Priority

### Phase 4 — GitOps with ArgoCD **[NEXT]**
- [ ] Install ArgoCD via Terraform Helm provider → `argocd` namespace
- [ ] Configure GitHub repo connection (deploy key or PAT)
- [ ] Create ArgoCD project + bootstrap app
- [ ] Implement app-of-apps pattern (root → child apps)
- [ ] Configure sync policies (auto-sync, self-heal, prune)
- [ ] Validate drift detection and reconciliation

### Phase 5 — Security Hardening
- [ ] Kyverno / OPA Gatekeeper admission policies
- [ ] Falco runtime security, Trivy image scanning
- [ ] External Secrets Operator + AWS Secrets Manager
- [ ] Network policies, Pod Security Standards

### Phase 6 — Service Mesh (Istio)
- [ ] Istio install, mTLS, ingress gateway, canary, circuit breaking, fault injection

### Phase 7 — Observability
- [ ] Prometheus, Grafana, Loki, Tempo, OpenTelemetry, AlertManager, dashboards, SLOs

### Phase 8 — Application (OpenTelemetry Demo)
- [ ] Deploy via ArgoCD, ingress, tracing, autoscaling
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

