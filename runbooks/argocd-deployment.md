# ArgoCD Deployment — State & Known Issues

## Overview
ArgoCD was deployed **manually** via Helm (not via the Ansible playbook in this repo, which is outdated). It runs in the `argocd` namespace and is exposed through Kong Ingress at `https://argocd.yelved.xyz`.

## Current Deployment

### Method
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 5.46.0
```

The Ansible playbook at `ansible/playbooks/deploy-argocd.yml` is **out of date**.

### Running Pods
| Pod | Status |
|---|---|
| `argocd-application-controller-0` | 1/1 Running |
| `argocd-applicationset-controller` | 1/1 Running |
| `argocd-notifications-controller` | 1/1 Running |
| `argocd-redis` | 1/1 Running |
| `argocd-repo-server` | 1/1 Running |
| `argocd-server` | 1/1 Running |
| `argocd-dex-server` | **Disabled** (scaled to 0) |

### Versions
- **Helm chart:** argo-cd 5.46.0
- **ArgoCD:** v2.8.3
- **Authentik:** 2026.5.2

## Service & Ingress

### Service
- **Type:** ClusterIP
- **Ports:** `80 → 8080`, `443 → 8080`

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  tls:
    - hosts:
        - argocd.yelved.xyz
      secretName: argocd-server-tls
  rules:
    - host: argocd.yelved.xyz
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

### DNS
- Route53 record: `argocd.yelved.xyz` → Kong NLB alias
- Managed by Terraform: `terraform/modules/route53/main.tf`

## Authentication

### Current: Authentik OIDC
- **OIDC Provider:** Authentik → Applications → Providers → "Provider for ArgoCD"
- **Application:** Authentik → Applications → Applications → "ArgoCD" (slug: `argo-cd`)
- **Issuer URL:** `https://auth.yelved.xyz/application/o/argo-cd/`
- **Client ID:** `xxxxxxx`
- **Client Secret:** Stored in `argocd-secret` under `oidc.Authentik.clientSecret`
- **Signing Key:** `authentik Self-signed Certificate`
- **Scopes:** `openid`, `profile`, `email`

### ConfigMap: `argocd-cm`
```yaml
url: https://argocd.yelved.xyz
oidc.config: |
  name: Authentik
  issuer: https://auth.yelved.xyz/application/o/argo-cd/
  clientID: xxxxxxx
  clientSecret: xxxxxxxx
  requestedScopes: ["openid", "profile", "email"]
```

### ConfigMap: `argocd-cmd-params-cm`
```yaml
server.insecure: "true"
```

### RBAC ConfigMap: `argocd-rbac-cm`
```yaml
policy.default: role:readonly
policy.csv: |
  g, authentik Admins, role:admin
  p, role:admin, *, *, *, allow
```

### Previous: Dex (DISABLED)
- Dex was configured for GitHub OAuth SSO (GitHub App ID: `Ov23ctOhGXMVhcioRbt8`)
- Scaled to 0: `kubectl scale deployment argocd-dex-server -n argocd --replicas=0`
- Dex config was **not codified** in the repo — existed only in cluster state

## Issues Encountered & Solutions

### 1. Ingress Loop (ERR_TOO_MANY_REDIRECTS)
**Problem:** Browser showed `ERR_TOO_MANY_REDIRECTS` when visiting `https://argocd.yelved.xyz`
**Root cause:** Three things interacting badly:
- `konghq.com/https-redirect-status-code: 301` annotation told Kong to redirect HTTP → HTTPS, but traffic was already HTTPS
- `konghq.com/protocols: https` told Kong to use HTTPS to the backend, but ArgoCD only serves HTTP on port 8080
- ArgoCD itself (`server.insecure` was not set) was also trying to redirect HTTP → HTTPS

**Fix:**
- Removed `konghq.com/https-redirect-status-code` and `konghq.com/protocols` annotations from the ingress
- Pointed ingress backend to port `80` (HTTP) instead of `443`
- Created `argocd-cmd-params-cm` ConfigMap with `server.insecure: "true"` to disable ArgoCD's own TLS redirect

**Lesson:** When Kong terminates TLS at the edge, the backend must accept plain HTTP. TLS at Kong, internal cluster traffic is HTTP on the private VPC network.

### 2. Authentik OIDC Slug Mismatch
**Problem:** ArgoCD couldn't connect to Authentik's OIDC endpoint (404 Not Found)
**Root cause:** The OIDC config in ArgoCD referenced `issuer: https://auth.yelved.xyz/application/o/argocd/` but the Authentik Application slug was `argo-cd` (with a hyphen)
**Fix:** Changed issuer URL to `https://auth.yelved.xyz/application/o/argo-cd/`
**Lesson:** Always match the Authentik Application slug exactly in the OIDC issuer URL.

### 3. Missing Signing Key
**Problem:** Authentik admin showed "Failed to fetch objects" for the Signing Key dropdown, and OIDC token signing failed
**Fix:** Created a self-signed certificate key in Authentik (System → Certificate-Key-Signing Keys → Create → Self-signed, RSA 4096) and assigned it to the OIDC Provider
**Lesson:** An OIDC provider needs a signing key assigned before it can issue tokens. Create one first.

### 4. Client ID Mismatch
**Problem:** After fixing the URL, Authentik showed "The client identifier (client_id) is missing or invalid"
**Fix:** Copied the correct Client ID from the Authentik provider page into ArgoCD's `oidc.config`
**Lesson:** Verify the Client ID is an exact match between the provider page and the ArgoCD config.

### 5. Invalid Client (Token Exchange)
**Problem:** After getting the callback from Authentik, ArgoCD showed `"invalid_client": "Client authentication failed"`
**Root cause:** The client secret was stored under the wrong key name in `argocd-secret`. The key name in the secret must match the `name:` field in the OIDC config (e.g., `oidc.Authentik.clientSecret` for `name: Authentik`)
**Fix:** Stored the client secret under `oidc.Authentik.clientSecret` (capital A) and removed the duplicate `oidc.authentik.clientSecret` (lowercase a) key
**Lesson:** The secret key suffix must match the OIDC provider `name:` field exactly (case-sensitive).

### 6. No Apps After Login
**Problem:** User logged in successfully via Authentik but saw no applications in ArgoCD
**Root cause:** RBAC policy didn't map the Authentik user group (`authentik Admins`) to the ArgoCD admin role
**Fix:** Added to `argocd-rbac-cm`:
```yaml
policy.csv: |
  g, authentik Admins, role:admin
  p, role:admin, *, *, *, allow
```
**Lesson:** Add RBAC group mappings in `argocd-rbac-cm` after switching identity providers.

### 7. Project Source Repo Not Found
**Problem:** New ArgoCD apps created by the bootstrap app showed `Unknown` sync status because the Helm repo wasn't in the project's allowed sources
**Root cause:** The `platform` AppProject is managed as a live resource in the cluster, not auto-synced from the Git repo. The `argocd/projects/platform.yaml` file was updated in Git but ArgoCD didn't apply it.
**Fix:** Applied the project YAML directly: `kubectl apply -f argocd/projects/platform.yaml`
**Lesson:** AppProject changes in Git don't auto-sync — apply them manually with `kubectl apply`.

## Key ConfigMaps

| Name | Namespace | Purpose |
|---|---|---|
| `argocd-cm` | argocd | Main config (OIDC, URL, features) |
| `argocd-cmd-params-cm` | argocd | CLI/server flags (`server.insecure`) |
| `argocd-rbac-cm` | argocd | RBAC role mappings |
| `argocd-secret` | argocd | Secrets (admin password, OIDC client secret, server key) |

## Redeployment Notes

If ArgoCD needs to be redeployed from scratch, follow these steps in order:

### Step 1: Install ArgoCD via Helm
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 5.46.0 \
  --wait \
  --timeout 10m
```

### Step 2: Apply Post-Install ConfigMaps
```bash
# Create argocd-cmd-params-cm (disables TLS redirect — Kong handles TLS at edge)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: argocd
data:
  server.insecure: "true"
EOF

# Update argocd-cm with Authentik OIDC config
kubectl patch configmap argocd-cm -n argocd --type=merge -p='{
  "data": {
    "url": "https://argocd.yelved.xyz",
    "oidc.config": "name: Authentik\nissuer: https://auth.yelved.xyz/application/o/argo-cd/\nclientID: xxxxxx\nrequestedScopes: [\"openid\", \"profile\", \"email\"]\n"
  }
}'

# Store OIDC client secret in argocd-secret
kubectl patch secret argocd-secret -n argocd --type=merge -p='{
  "data": {
    "oidc.Authentik.clientSecret": "'$(echo -n 'xxxxxxxxx' | base64 -w0)'"
  }
}'

# Update RBAC to map authentik Admins group to admin role
kubectl patch configmap argocd-rbac-cm -n argocd --type=merge -p='{
  "data": {
    "policy.default": "role:readonly",
    "policy.csv": "g, authentik Admins, role:admin\np, role:admin, *, *, *, allow\n"
  }
}'

# Restart ArgoCD server to pick up new config
kubectl rollout restart deployment argocd-server -n argocd
```

### Step 3: Create Kong Ingress
```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  tls:
    - hosts:
        - argocd.yelved.xyz
      secretName: argocd-server-tls
  rules:
    - host: argocd.yelved.xyz
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
EOF
```

### Step 4: Disable Dex (old SSO)
```bash
kubectl scale deployment argocd-dex-server -n argocd --replicas=0
```

### Step 5: Apply ArgoCD Project (bootstrap AppProject)
```bash
# The project in Git doesn't auto-sync — apply it manually
kubectl apply -f argocd/projects/platform.yaml
```

### Step 6: Verify
1. Wait for TLS certificate: `kubectl get certificate -n argocd argocd-server-tls`
2. Visit `https://argocd.yelved.xyz` — should see "LOGIN VIA AUTHENTIK" button
3. Log in via Authentik — should see all apps
4. Bootstrap app will create all child applications automatically

> **Note:** If authentication shows an unknown/invalid client ID, the OIDC Provider in Authentik may need to be recreated. See the Authentik section above for provider details.
