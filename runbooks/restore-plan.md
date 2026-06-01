# Restore Plan — Cluster Destroy & Rebuild

Use this when destroying the dev cluster for cost savings and rebuilding later.

---

## Before Destroy — Backup Checklist ☑️

Run these **before** `terraform destroy`:

```bash
# 1. Verify local.auto.tfvars has your OAuth credentials
cat terraform/environments/dev/local.auto.tfvars
# Expected: argocd_oauth_client_id, argocd_oauth_client_secret, argocd_domain

# 2. Verify your AWS credentials work
aws sts get-caller-identity

# 3. Make sure all uncommitted code is pushed to GitHub
git status
git push origin feat/phase-4-argocd
```

### What you'll lose (that can't be restored from Git)

| Item | Location | Restore method |
|---|---|---|
| OAuth client secret | `local.auto.tfvars` | Must exist on disk — **back this up** |
| Let's Encrypt cert | `argocd-server-tls` Secret | Auto-renews via HTTP-01 challenge |
| ArgoCD admin password | `argocd-initial-admin-secret` | New one generated on restore |
| K8s Secrets | All namespaces | Recreated by Helm charts on apply |

---

## Restore Steps

**Estimated total time: ~35-40 minutes**

### Phase 1: Terraform Apply (~25 min)

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply -auto-approve
```

**Watch for known issues:**
- EBS CSI addon may fail on first apply — retry usually works
- VPC CNI addon may timeout — run `terraform apply` again

### Phase 2: Wait for Cluster Health (~5 min)

```bash
kubectl get nodes -w           # Expected: 3 Ready
kubectl get pods -n kube-system # Expected: all Running
```

### Phase 3: ArgoCD Sync (~10 min)

```bash
# Wait for ArgoCD pods (7 pods Running)
kubectl get pods -n argocd -w

# Trigger nginx-ingress sync (deploys NLB)
kubectl patch application nginx-ingress -n argocd --type merge \
  -p '{"operation":{"sync":{"prune":true}}}'

# Wait for NLB (~2-3 min)
kubectl get svc -n ingress-nginx -w

# Trigger cert-manager sync
kubectl patch application cert-manager -n argocd --type merge \
  -p '{"operation":{"sync":{"prune":true}}}'

# Wait for cert (~1-2 min)
kubectl get certificate -n argocd -w
# Expected: Ready=True
```

### Phase 4: Verify OAuth + TLS (~5 min)

```bash
# Restart Dex to pick up OAuth config
kubectl rollout restart deployment argocd-dex-server -n argocd

# Get NLB hostname
NLB=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Check if your IP changed — update local.auto.tfvars if so
echo "New NLB: $NLB"
echo "Your IP: $(curl -s ifconfig.me)"
```

If your laptop public IP changed, update `terraform/environments/dev/local.auto.tfvars`:

```bash
# argocd_domain = "argocd.YOUR_NEW_IP.nip.io"
# Then: terraform apply
```

### Phase 5: Validation ✅

```bash
kubectl get pods -A | grep -v Running | grep -v Completed
kubectl get certificate -n argocd
echo "URL: https://argocd.$(curl -s ifconfig.me).nip.io"
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `terraform apply` fails on EBS CSI | Run `terraform apply` again (timing issue) |
| ArgoCD shows "OutOfSync" | Auto-syncs within 3 min, or manually trigger sync |
| nginx-ingress NLB not provisioning | May take 2-3 min — check `kubectl get svc -n ingress-nginx -w` |
| cert-manager certificate stuck | Check `kubectl describe certificate -n argocd` for challenge errors |
| GitHub login doesn't redirect | Restart Dex: `kubectl rollout restart deploy/argocd-dex-server -n argocd` |
| GitHub login says "not in org" | Verify your GitHub account is member of `yelved-org` |
| nip.io not resolving | Use NLB hostname directly: `https://<NLB_HOSTNAME>` |
| ArgoCD admin password needed | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` |

---

## Manual Steps Summary

These are the things that **can't be fully automated** and need manual attention:

1. **Update nip.io domain** — if your laptop IP changes, update `argocd_domain` in `local.auto.tfvars` and re-run `terraform apply`
2. **OAuth client secret** — must be present in `local.auto.tfvars` (gitignored, backed up separately)
3. **Manually trigger ArgoCD syncs** — ArgoCD will auto-sync but triggering manually speeds it up
4. **Restart Dex** — OAuth config requires Dex restart to pick up changes

---

## Cost Savings

| Duration | Cost Saved |
|---|---|
| 1 week | ~$75 |
| 2 weeks | ~$150 |
| 1 month | ~$300 |

**Tradeoff:** ~40 min to rebuild. Worth it for 2+ weeks away.
