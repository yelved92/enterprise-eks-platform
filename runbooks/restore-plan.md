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
| **ArgoCD unreachable (NLB replaced)** | See [NLB Recreation Recovery](#nlb-recreation-recovery) below |

---

## NLB Recreation Recovery

Use this when the nginx-ingress NLB is deleted or replaced (e.g., deleting the LoadBalancer Service, or when ArgoCD was previously working through a rogue/leftover NLB that got cleaned up).

### Symptoms
- `https://argocd.<IP>.nip.io` times out (`ERR_CONNECTION_TIMED_OUT`)
- curl returns `HTTP 000`
- nginx pods are healthy but new NLB IPs don't match the nip.io domain

### Root Cause
The `nip.io` domain hardcodes a specific IP (e.g., `argocd.52.6.201.161.nip.io`). If the NLB is replaced, the IP changes and the old domain no longer resolves to the new NLB.

### Recovery Steps

```bash
# 1. Get the new NLB DNS name
NLB=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "New NLB: $NLB"

# 2. Get the new NLB IPs
nslookup $NLB

# 3. Pick a working IP and update the domain in Terraform vars
# Edit terraform/environments/dev/local.auto.tfvars:
#   argocd_domain = "argocd.<NEW_IP>.nip.io"

# 4. Apply the change
cd terraform/environments/dev
terraform apply -auto-approve

# 5. If preserve_client_ip.enabled=true and NLB was recreated,
#    the private subnet NACL may need an outbound ephemeral port rule
#    (This is standard for internet-facing workloads with preserve_client_ip):
aws ec2 create-network-acl-entry --region us-east-1 \
  --network-acl-id <PRIVATE_SUBNET_NACL_ID> \
  --rule-number 215 \
  --protocol tcp \
  --port-range From=1024,To=65535 \
  --cidr-block 0.0.0.0/0 \
  --egress \
  --rule-action allow

# 6. Restart Dex to pick up new domain
kubectl rollout restart deployment argocd-dex-server -n argocd
kubectl rollout restart deployment argocd-server -n argocd

# 7. Update GitHub OAuth App callback URL
#    Go to: https://github.com/settings/developers
#    Update "Authorization callback URL" to:
#    https://argocd.<NEW_IP>.nip.io/api/dex/callback
#    Click "Update application"

# 8. Wait for Let's Encrypt cert (~2-3 min)
kubectl get certificate -n argocd -w
# Expected: Ready=True

# 9. Verify access
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" \
  https://argocd.<NEW_IP>.nip.io/ --connect-timeout 10
# Expected: 200 or 302
```

### NACL Context
With `preserve_client_ip.enabled=true`, the NLB preserves the original client IP. Response traffic from worker nodes flows back through the NAT Gateway. The private subnet's **outbound NACL** must allow ephemeral ports (1024-65535) to `0.0.0.0/0` for responses to reach the client. This is standard and safe for internet-facing workloads.

### GitHub OAuth Note
After changing the domain, the GitHub OAuth App must be updated manually — there's no API to automate this. The callback URL must exactly match `https://argocd.<NEW_IP>.nip.io/api/dex/callback`.

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
