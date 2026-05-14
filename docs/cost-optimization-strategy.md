"# Cost Optimization Strategy

> **Documentation of cost optimization strategies for the enterprise EKS platform, balancing production realism with cost efficiency.**

## Overview

This document outlines the cost optimization strategy for the Enterprise-Grade AWS EKS Platform. The platform is designed to be production-grade while remaining cost-conscious, prioritizing learning enterprise architecture without unnecessary AWS spend.

## Design Philosophy

### Production vs Lab Tradeoffs

| Aspect | Production Best Practice | Lab/Personal Project |
|--------|------------------------|---------------------|
| **Cluster Count** | 2 clusters (Blue/Green) | 1-2 clusters (minimal sizing) |
| **Node Sizes** | t3.large, t3.xlarge | t3.medium, t3.small |
| **Multi-AZ** | 3 AZs (minimum) | 2 AZs (minimum) |
| **NAT Gateways** | 1 per AZ | 1 total (single AZ) |
| **Data Retention** | 90-365 days | 7-30 days |
| **Backup Frequency** | Daily/Hourly | Weekly |

## Major AWS Cost Drivers in EKS

### 1. EC2 Instances (Node Groups)
- **Primary Cost Driver:** Compute resources for worker nodes
- **Strategy:** Use Spot instances for non-critical workloads, right-size instances
- **Estimated Monthly Cost (Lab):** $50-150/month (2x t3.medium, 1x t3.large)

### 2. NAT Gateways
- **Primary Cost Driver:** Data processing + hourly charges (~$32/month each)
- **Strategy:** Minimize NAT Gateway count; single NAT for lab, 1 per AZ for production
- **Estimated Monthly Cost:** $32-96/month

### 3. EBS Volumes
- **Primary Cost Driver:** Storage for nodes and persistent volumes
- **Strategy:** Use gp3 volumes, delete unassociated volumes, lifecycle management
- **Estimated Monthly Cost:** $10-30/month

### 4. Data Transfer
- **Primary Cost Driver:** Cross-AZ and Internet egress
- **Strategy:** Keep workloads in same AZ where possible, use VPC endpoints
- **Estimated Monthly Cost:** $5-20/month

### 5. Load Balancers
- **Primary Cost Driver:** ALB/NLB hourly charges + LCU usage
- **Strategy:** Minimize ingress controllers, consolidate services
- **Estimated Monthly Cost:** $20-50/month

### 6. Observability Stack
- **Primary Cost Driver:** CloudWatch Logs, metrics, traces
- **Strategy:** Set log retention limits, filter noisy logs, use Prometheus locally
- **Estimated Monthly Cost:** $10-30/month

## Cost Optimization Strategies

### Compute Optimization

#### Spot Instances
```hcl
# Karpenter node pool with spot preference
resource \"karpenter_node_pool\" \"default\" {
  # ... existing code ...
  spec {
    template {
      spec {
        requirements {
          key      = \"karpenter.sh/capacity-type\"
          operator = \"In\"
          values   = [\"spot\", \"on-demand\"]
        }
      }
    }
    limits {
      cpu    = 100
      memory = \"400Gi\"
    }
    disruption {
      consolidation_policy = \"WhenUnderutilized\"
      expire_after         = \"720h\"  # 30 days
    }
  }
}
```

#### Right-Sizing
- Start small (t3.medium), monitor and scale
- Use Kubernetes resource requests/limits
- Enable Cluster Autoscaler / Karpenter
- Set pod resource quotas per namespace

#### Scaledown
- Configure Karpenter to consolidate underutilized nodes
- Set cluster autoscaler scale-down thresholds
- Implement `cluster-autoscaler.kubernetes.io/scale-down-disabled` annotations

### Networking Optimization

#### NAT Gateway Strategy
```
Production: 1 NAT Gateway per AZ (3 total for 3 AZs)
Lab:        1 NAT Gateway for all AZs (or use public subnets where safe)
```

#### VPC Endpoints
- Use Gateway Endpoints for S3 and DynamoDB (free)
- Use Interface Endpoints only when required (hourly cost)
- Evaluate cost vs benefit of each endpoint

### Storage Optimization

#### EBS Volume Lifecycle
```yaml
# StorageClass with gp3 and deletion policy
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-retain
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: \"3000\"
  throughput: \"125\"
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

#### Log Retention
| Service | Production | Lab |
|---------|------------|-----|
| CloudWatch Logs | 365 days | 7 days |
| Loki Logs | 90 days | 14 days |
| Prometheus Metrics | 30 days | 7 days |
| Grafana Dashboards | Indefinite | Indefinite |

### Observability Optimization

#### Selective Monitoring
- Monitor critical namespaces with full telemetry
- Apply sampling rates to traces (1-10% in production)
- Use aggregated metrics instead of detailed logging
- Configure alerting thresholds to avoid noise

#### Cost-Efficient Logging
```yaml
# Loki configuration with retention and compression
loki:
  config:
    table_manager:
      retention_deletes_enabled: true
      retention_period: 168h  # 7 days for lab
    ingester:
      chunk_encoding: snappy
      chunk_target_size: 1536000
```

## Monthly Cost Estimate (Lab Environment)

| Component | Estimated Cost |
|-----------|---------------|
| EC2 Instances (3x t3.medium, 1x t3.large) | $80-120 |
| NAT Gateway (1x) | $32 |
| EBS Volumes (3x 20GB gp3) | $6 |
| Data Transfer | $5-10 |
| Load Balancers (1x ALB) | $20 |
| CloudWatch Logs | $5-10 |
| VPC Endpoints | $7 |
| **Total Estimated** | **$155-205/month** |

> **Note:** Actual costs may vary. Use AWS Cost Explorer and Budgets to monitor.

## FinOps Best Practices

### 1. Tagging Strategy
```hcl
# Required tags on all resources
tags = {
  Environment = var.environment
  Project     = \"enterprise-eks-platform\"
  ManagedBy   = \"terraform\"
  CostCenter  = \"platform-engineering\"
  CreatedBy   = \"iac\"
}
```

### 2. Budget Alerts
```bash
# Create AWS Budget alert
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget-file budget.json
```

### 3. Cost Allocation
- Tag all resources with environment and workload
- Use AWS Cost Categories for grouping
- Set up AWS Budgets with alerts at 50%, 80%, 100%

### 4. Scheduled Shutdown
```yaml
# CronJob for scaling down dev cluster overnight
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-down-dev
spec:
  schedule: \"0 20 * * 1-5\"  # 8 PM weekdays
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scale-down
            image: bitnami/kubectl
            command:
            - /bin/sh
            - -c
            - kubectl scale deployment --all --replicas=0 -n <namespace>
```

## Cost Monitoring Dashboards

### Grafana Dashboard
- Node utilization (CPU, Memory, Network)
- Cluster resource efficiency
- Namespace resource consumption
- Spot instance savings
- Hourly/daily cost trends

### AWS Cost Explorer
- Monthly spending trends
- Service breakdown
- Environment cost comparison
- Tag-based filtering

## Common Cost Pitfalls

### 1. Overprovisioned Nodes
- **Problem:** Requesting too many or too large instances
- **Solution:** Start small, monitor, and scale up

### 2. Idle Resources
- **Problem:** Resources provisioned but not utilized
- **Solution:** Enable cluster scaling, set resource limits

### 3. Expensive Storage
- **Problem:** Using io1/io2 instead of gp3
- **Solution:** Default to gp3, use io1 only for high-performance workloads

### 4. Unattached Resources
- **Problem:** Orphaned ELBs, EBS volumes, Elastic IPs
- **Solution:** Regular cleanup scripts, Terraform lifecycle management

### 5. Observability Cost Explosion
- **Problem:** Logging and monitoring everything at full detail
- **Solution:** Selective sampling, retention limits, aggregation

## Implementation Strategy

### Phase 1: Baseline (Current)
- Deploy minimal infrastructure
- Enable cost monitoring
- Set budgets

### Phase 2: Optimization
- Implement Spot instances
- Right-size node groups
- Configure log retention

### Phase 3: Advanced
- Karpenter consolidation
- Scheduled scaling
- FinOps dashboards

## Next Steps

1. Enable AWS Budgets and alerts
2. Apply cost allocation tags to all Terraform resources
3. Configure log retention policies
4. Set up cost monitoring dashboard in Grafana
5. Review and adjust instance sizes monthly"