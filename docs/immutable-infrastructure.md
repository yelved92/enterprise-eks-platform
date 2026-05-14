"# Immutable Infrastructure Strategy

> **Documentation of the immutable infrastructure principles and implementation for the enterprise EKS platform.**

## Overview

This document defines the immutable infrastructure strategy for the Enterprise-Grade AWS EKS Platform. Immutable infrastructure is a paradigm where infrastructure components are replaced rather than modified after deployment. This approach ensures consistency, reproducibility, and reliability.

## Core Principles

### 1. No In-Place Modifications

```diff
- ❌ SSH into a server and modify configuration
- ❌ Patch a running instance
- ❌ Manually edit Kubernetes resources
+ ✅ Destroy and recreate components
+ ✅ Deploy new versions alongside existing
+ ✅ Traffic switch between versions
```

### 2. Golden Images / Immutable Artifacts

```
┌─────────────────────────────────────────────────────────┐
│                    Artifact Registry                       │
├─────────────┬──────────────┬──────────────────────────────┤
│ AMI Images  │ Containers   │ Terraform Modules            │
│ (EC2)       │ (Docker)     │ (IaC)                        │
├─────────────┼──────────────┼──────────────────────────────┤
│ Versioned   │ Versioned    │ Versioned via Git            │
│ Immutable   │ Immutable    │ Immutable history            │
│ Reusable    │ Reusable     │ Reviewable                   │
└─────────────┴──────────────┴──────────────────────────────┘
```

### 3. Infrastructure as Code (IaC)

All infrastructure is defined in code:
- **Terraform**: AWS resources (VPC, EKS, IAM, networking)
- **Helm**: Application and service configurations
- **Kubernetes YAML**: Deployments, services, policies
- **Ansible**: Bootstrap and configuration management

### 4. Automated Deployments

- No manual `kubectl` or `aws` commands for production changes
- All changes go through CI/CD pipelines
- GitOps ensures cluster state matches Git

## Implementation Strategy

### Terraform: Immutable Infrastructure

#### State Management

```hcl
# Backend configuration for state immutability
terraform {
  backend "s3" {
    bucket         = "enterprise-eks-platform-tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
    key            = "${var.environment}/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    
    # Enable state versioning for rollback
    # versioning = true (enabled on bucket)
  }
}
```

#### Resource Lifecycle

```hcl
# Example: Immutable launch template (replaced on change)
resource "aws_launch_template" "eks_nodes" {
  name          = "eks-${var.cluster_name}-node-${var.node_group_name}"
  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = var.instance_types[0]
  
  # Immutable: any change creates new template
  lifecycle {
    create_before_destroy = true
  }
  
  # User data for node bootstrap (immutable)
  user_data = base64encode(templatefile("${path.module}/templates/node-userdata.sh", {
    cluster_name       = var.cluster_name
    cluster_endpoint   = var.cluster_endpoint
    cluster_ca         = var.cluster_certificate_authority_data
    bootstrap_args     = "--kubelet-extra-args '--node-labels=node-type=${var.node_type}'"
  }))
}
```

### Kubernetes: Immutable Workloads

#### Deployment Strategy

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    spec:
      # Immutable container images (version pinned)
      containers:
      - name: app
        image: my-app:v1.2.3  # Immutable tag
        ports:
        - containerPort: 8080
```

#### Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

### GitOps: Immutable Cluster State

#### ArgoCD Sync Policy

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  syncPolicy:
    automated:
      prune: true        # Remove resources not in Git
      selfHeal: true     # Revert manual changes
      allowEmpty: false   # Don't prune all resources
    syncOptions:
    - CreateNamespace=true
    - PruneLast=true       # Prune after sync
    - ApplyOutOfSyncOnly=true  # Only apply out-of-sync resources
```

## Mutable vs Immutable Comparison

| Aspect | Mutable Infrastructure | Immutable Infrastructure |
|--------|----------------------|------------------------|
| **Change Model** | Modify in place | Replace entirely |
| **Configuration Drift** | Common, hard to detect | None (Git is source of truth) |
| **Rollback** | Complex, error-prone | Simple (deploy previous version) |
| **Consistency** | Varies over time | Guaranteed from artifact |
| **Security Updates** | Patch running systems | Replace with patched version |
| **Audit Trail** | None or manual | Complete Git history |
| **Testing** | Hard to reproduce | Same artifact in all envs |
| **Operational Complexity** | Lower initial, higher over time | Higher initial, lower over time |

## Blue/Green with Immutable Infrastructure

```
1. Build new artifact (AMI, container, Terraform plan)
2. Deploy new version to Green environment
3. Validate Green environment (automated tests)
4. Switch traffic from Blue → Green
5. Keep Blue as rollback target
6. Decommission Blue when confident

┌─────────────┐    ┌─────────────┐
│  Blue (v1)  │    │ Green (v2)  │
│  Immutable  │    │  Immutable  │
│  Artifact   │    │  Artifact   │
│  (old)      │    │  (new)      │
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
         ┌──────▼──────┐
         │  Route53    │
         │  Weighted   │
         │  Routing    │
         └─────────────┘
```

## Terraform Lifecycle Rules

### create_before_destroy

```hcl
resource "aws_instance" "example" {
  # ... configuration ...
  
  lifecycle {
    create_before_destroy = true  # Creates new before destroying old
  }
}
```

### prevent_destroy

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "enterprise-eks-platform-tfstate"
  
  lifecycle {
    prevent_destroy = true  # Never destroy this resource
  }
}
```

### ignore_changes

```hcl
resource "aws_autoscaling_group" "eks_nodes" {
  # ... configuration ...
  
  lifecycle {
    ignore_changes = [
      desired_capacity,  # Managed by Cluster Autoscaler
      tag,               # Managed by AWS services
    ]
  }
}
```

## Security Benefits

| Security Aspect | How Immutable Infrastructure Helps |
|----------------|------------------------------------|
| **Vulnerability Patching** | Replace with patched image, no in-place patching |
| **Configuration Drift** | Immutable instances ensure consistent security posture |
| **Supply Chain Security** | Signed, versioned artifacts with SBOM |
| **Incident Response** | Replace compromised instance, forensic analysis preserved |
| **Compliance** | Git audit trail for all changes |

## Operational Implications

### Pros
- **Consistency**: Every deployment is identical
- **Reliability**: No configuration drift
- **Simplicity**: Simple rollback (deploy previous version)
- **Testing**: Same artifact tested in all environments
- **Security**: Fresh instances with latest patches

### Cons
- **Deployment Time**: Full replacement takes longer than patching
- **State Management**: Must handle stateful workloads carefully
- **Cold Start**: New instances may need warm-up time
- **Resource Usage**: Multiple versions may exist simultaneously
- **Complexity**: Requires robust CI/CD pipeline

## Stateful Workloads

### Databases and Persistent Storage

```yaml
# StatefulSet with persistent volumes
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15.4  # Immutable tag
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3-retain
      resources:
        requests:
          storage: 100Gi
```

### Data Migration Strategy

```bash
# Pre-deployment: Backup data
kubectl exec -n database postgres-0 -- pg_dumpall > pre-upgrade-backup.sql

# Deployment: Replace database with new version
kubectl delete statefulset postgres --cascade=orphan
kubectl apply -f postgres-v2.yaml

# Post-deployment: Validate data integrity
kubectl exec -n database postgres-0 -- psql -c "SELECT count(*) FROM information_schema.tables;"
```

## Automation with CI/CD

### Pipeline for Immutable Deployments

```yaml
name: Immutable Deployment

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
      - 'kubernetes/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build immutable artifact
        run: |
          # Build versioned artifact
          docker build -t my-app:${{ github.sha }} .
          docker push my-app:${{ github.sha }}
      
      - name: Update Terraform with new artifact version
        run: |
          # Update version in Terraform variables
          sed -i "s/image_tag = \".*\"/image_tag = \"${{ github.sha }}\"/" terraform/environments/dev/terraform.tfvars
  
  deploy-green:
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Apply Terraform to Green environment
        run: |
          terraform init
          terraform apply -auto-approve -target=module.eks_green
  
  validate:
    needs: [deploy-green]
    runs-on: ubuntu-latest
    steps:
      - name: Run validation tests against Green
        run: |
          # Integration tests, security scans, etc.
          ./scripts/validate-cluster.sh green
  
  switch-traffic:
    needs: [validate]
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Switch Route53 traffic to Green
        run: |
          # Traffic switch automation
          ./scripts/traffic-switch.sh 100:green 0:blue
  
  decommission-blue:
    needs: [switch-traffic]
    runs-on: ubuntu-latest
    if: success()
    steps:
      - name: Destroy old Blue environment
        run: |
          terraform destroy -auto-approve -target=module.eks_blue
```

## Implementation Checklist

### Phase 1: Foundation (This Project)
- [ ] All Terraform resources use `create_before_destroy` where applicable
- [ ] Stateful workloads use StatefulSets with persistent volumes
- [ ] Container images use immutable tags (SHA or versioned)
- [ ] ArgoCD configured with automated sync and self-healing
- [ ] Rollback procedures documented

### Phase 2: Advanced
- [ ] AMI pipeline for immutable node images
- [ ] Container image signing with Cosign
- [ ] SBOM generation and storage
- [ ] Automated canary deployments
- [ ] Blue/Green traffic switching automation

### Phase 3: Operational Excellence
- [ ] Chaos engineering tests for immutability
- [ ] Cost analysis of replace vs patch
- [ ] Immutable infrastructure runbooks
- [ ] Training for operations team

## Common Anti-Patterns

### ❌ Configuration Drift
```diff
- Manually editing Kubernetes resources with kubectl
- SSH-ing into nodes to install packages
- Modifying Terraform state directly
```

### ❌ Mutable Deployments
```diff
- kubectl set image deployment/my-app my-app=my-app:v2
- kubectl rollout restart deployment/my-app
- Manual rolling updates without Git tracking
```

### ❌ Imperative Operations
```diff
- aws ec2 modify-instance-attribute
- aws autoscaling update-auto-scaling-group
- aws eks update-cluster-config
```

### ✅ Correct Approach
```diff
+ Git commit changes to Terraform/Kubernetes manifests
+ Code review and CI/CD pipeline
+ ArgoCD syncs cluster to desired state
+ Blue/Green deployment for zero-downtime
```

## References

- [Martin Fowler: Immutable Server](https://martinfowler.com/bliki/ImmutableServer.html)
- [AWS Well-Architected Framework: Infrastructure as Code](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/infrastructure-as-code.html)
- [Kubernetes: Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)
- [Terraform: Lifecycle Meta-Argument](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)

## Next Steps

1. Implement `create_before_destroy` in all Terraform resources
2. Configure ArgoCD with automated self-healing
3. Document rollback procedures for each component
4. Create immutable deployment pipeline"