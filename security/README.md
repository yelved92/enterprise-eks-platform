# Security Hardening

This directory contains security configurations for the Enterprise EKS Platform Phase 5.

## Components

### Kyverno (Admission Policies)
- **Location:** `kyverno/policies/`
- **Purpose:** Kubernetes-native admission policies to enforce security standards
- **Policies:**
  - `disallow-privileged-containers.yaml` — Prevents privileged containers
  - `require-non-root-users.yaml` — Ensures containers run as non-root
  - `disallow-host-network-ports.yaml` — Blocks host network/port access
  - `require-resource-limits.yaml` — Requires resource limits on all containers

### Falco (Runtime Security)
- **Location:** Deployed via ArgoCD (`argocd/applications/falco.yaml`)
- **Purpose:** Runtime threat detection using eBPF
- **Output:** Logs to stdout (view via `kubectl logs -n falco ds/falco`)

### External Secrets Operator (Secret Management)
- **Location:** `external-secrets/`
- **Purpose:** Sync secrets from AWS Secrets Manager to Kubernetes
- **Components:**
  - `secret-store.yaml` — AWS Secrets Manager SecretStore
  - `test-secret.yaml` — Example ExternalSecret for testing

### Network Policies
- **Location:** `network-policies/`
- **Purpose:** Namespace isolation and traffic control
- **Policies:**
  - `default-deny-all.yaml` — Default-deny for all namespaces
  - `allow-core-dns.yaml` — Allow DNS queries to CoreDNS
  - `allow-argocd.yaml` — Allow ArgoCD component communication
  - `allow-otel-demo.yaml` — Allow OTel Demo service-to-service traffic

## Deployment

All components are deployed via ArgoCD GitOps:

```bash
# Kyverno
argocd/applications/kyverno.yaml

# Falco
argocd/applications/falco.yaml

# External Secrets Operator
argocd/applications/external-secrets.yaml
```

## Validation

### Kyverno
```bash
# Test privileged pod denial
kubectl run test-privileged --image=nginx --privileged
# Expected: Error: admission webhook "validate.kyverno.svc-fail" denied the request
```

### Falco
```bash
# View Falco logs
kubectl logs -n falco ds/falco --tail=100
```

### External Secrets
```bash
# Create test secret in AWS Secrets Manager
aws secretsmanager create-secret --name enterprise-eks-platform/test-secret --secret-string '{"password":"my-secret-password"}'

# Check if secret synced
kubectl get secret test-secret -n test-secrets -o yaml
```

### Network Policies
```bash
# Test connectivity between namespaces
kubectl run test-pod --image=nginx -n default
kubectl exec -n default test-pod -- curl http://otel-frontend.opentelemetry-demo:8080
# Expected: Connection timeout (default-deny policy)
```
