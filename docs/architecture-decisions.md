# Architecture Decision Records (ADR)

## ADR-001: Repository Structure

**Status:** Accepted

**Context:**
The project requires a clean, modular, enterprise-grade repository layout that separates concerns and allows teams to work independently on infrastructure, Kubernetes manifests, security policies, and documentation.

**Decision:**
Use a top-level directory structure with clear separation:
- `terraform/` — Infrastructure as Code
- `kubernetes/` — Raw Kubernetes manifests
- `argocd/` — GitOps configuration
- `helm/` — Helm charts
- `observability/` — Monitoring, logging, tracing config
- `security/` — Security tool configurations
- `apps/` — Application manifests
- `scripts/` — Utility scripts
- `docs/` — Documentation
- `diagrams/` — Architecture diagrams
- `runbooks/` — Operational runbooks
- `policies/` — Policy-as-code
- `ansible/` — Configuration management (future use)

**Alternatives Considered:**
- Monolithic single-directory approach (rejected — too chaotic for enterprise use)
- Per-environment directory at root (rejected — too repetitive, env-specific configs live in terraform/environments)

**Pros:**
- Clear separation of concerns
- Easy for different teams to navigate
- Follows industry best practices
- Scalable for multi-environment, multi-region deployments

**Cons:**
- More directories to manage
- Requires documentation for team onboarding

**Operational Impact:**
- Reduces cognitive load for platform engineers
- Enables CI/CD pipelines to target specific directories

**Security Implications:**
- Security policies isolated in `policies/` and `security/` directories
- Clear boundaries for RBAC in Git repository

---

## ADR-002: Session Continuity via Documentation

**Status:** Accepted

**Context:**
This project will be implemented across multiple AI chat sessions. Without persistent state, each new session would lose context.

**Decision:**
Maintain four key documentation files:
- `docs/project-state.md` — Current phase, completed components, pending tasks, infrastructure status
- `docs/progress-log.md` — Chronological engineering log
- `docs/architecture-decisions.md` — ADR-style decision records
- `docs/todo.md` — Task management with priority categorization

**Alternatives Considered:**
- Single state file (rejected — too much information, hard to maintain)
- No documentation (rejected — would break session continuity)

**Pros:**
- Enables seamless session resumption
- Forces disciplined engineering documentation
- Serves as team onboarding material

**Cons:**
- Requires manual updates after each phase
- Risk of documentation drift if not maintained

**Operational Impact:**
- Essential for multi-session AI collaboration
- Mirrors real enterprise documentation practices

**Security Implications:**
- No sensitive information stored in documentation
- ADRs capture security decision context

---

## ADR-003: Automation-First Approach (No AWS Console)

**Status:** Accepted

**Context:**
The updated project requirements mandate that no manual infrastructure creation or configuration through the AWS Console should be required except for unavoidable initial account/bootstrap setup. Everything must be declarative, version-controlled, and automated.

**Decision:**
Adopt a strict automation-first philosophy:
- All infrastructure provisioned via Terraform (IaC)
- All Kubernetes resources deployed via ArgoCD (GitOps)
- All configuration management via Ansible
- All CI/CD pipelines in GitHub Actions
- AWS Console used only for: observability, auditing, emergency break-glass operations

**Alternatives Considered:**
- Hybrid approach (some console, some IaC) — rejected; creates drift, unreproducible environments
- CloudFormation instead of Terraform — rejected; Terraform is industry standard for multi-cloud, has better state management
- Manual bootstrap via console scripts — rejected; defeats reproducibility

**Pros:**
- Fully reproducible environments
- Complete audit trail via Git
- No configuration drift between environments
- Enables automated disaster recovery
- Industry best practice for enterprise

**Cons:**
- Higher initial setup complexity
- Requires learning multiple automation tools
- Bootstrap steps still need occasional console access

**Operational Impact:**
- Changes require Git commits, reviews, pipeline execution
- Rollbacks are Git revert + pipeline re-run
- Incident response may need emergency console access (documented in runbooks)

**Security Implications:**
- Reduces human error risk
- All changes are traceable
- Prevents unauthorized infrastructure changes
- Enables automated policy enforcement

---

## ADR-004: Terraform Remote State with S3 + DynamoDB

**Status:** Accepted

**Context:**
Terraform state files contain sensitive information and must be stored securely, shared across team members, and protected from concurrent modifications.

**Decision:**
Use S3 as the remote state backend with DynamoDB for state locking. This is the AWS-recommended approach for production Terraform deployments.

**Alternatives Considered:**
- Local state — rejected; not shareable, no locking, dangerous for team use
- Terraform Cloud — viable but adds cost and external dependency
- GitLab backend — viable but adds external dependency

**Pros:**
- Industry standard for AWS Terraform
- State encryption at rest (S3 SSE-S3/KMS)
- DynamoDB prevents concurrent applies
- Supports state versioning
- No additional cost (S3 + DynamoDB are minimal)

**Cons:**
- Bootstrap requires manual S3 bucket + DynamoDB table creation (one-time console access)
- State file can become large for complex infrastructures

**Operational Impact:**
- Enables safe team collaboration
- Supports CI/CD pipeline integration
- Enables state rollback via S3 versioning

**Security Implications:**
- State encryption protects secrets (db passwords, etc.)
- DynamoDB locking prevents corruption
- S3 bucket policies should restrict access

---

## ADR-005: Blue/Green Cluster Architecture

**Status:** Accepted

**Context:**
The platform requires zero-downtime upgrades, disaster recovery failover, and safe cluster migration.

**Decision:**
Deploy two EKS clusters in a Blue/Green pattern:
- **Blue cluster** — Active, serving production traffic
- **Green cluster** — Standby/passive, used for upgrades, DR, testing

Route53 with weighted/failover routing policies will manage traffic switching during failover events.

**Alternatives Considered:**
- Single cluster with node group upgrades — rejected; higher risk during upgrades, no DR isolation
- Canary clusters — rejected; adds complexity for limited benefit over Blue/Green
- Multi-region clusters — ideal for true DR but costly for this project; Blue/Green in single region with multi-AZ is sufficient

**Pros:**
- Zero-downtime cluster upgrades
- Isolation for DR testing
- Safe rollback by switching traffic back to Blue
- Realistic enterprise pattern

**Cons:**
- Double the infrastructure cost (2 clusters)
- Requires data synchronization strategy
- More complex networking and IAM

**Operational Impact:**
- Cluster upgrades become a controlled traffic switch
- DR testing is non-disruptive (test on Green)
- Requires careful Route53 management

**Security Implications:**
- Green cluster should have identical security posture
- Data replication between clusters must be encrypted
- IAM roles must be duplicated across clusters
---

## ADR-006: Single EKS Cluster First — Phased Introduction of Blue/Green

**Status:** Accepted

**Context:**
ADR-005 established Blue/Green cluster architecture as the target state. However, deploying two clusters before any applications are running adds unnecessary complexity, doubles infrastructure cost during development, and complicates initial debugging. The team needs a working cluster to validate networking, IAM, ingress, GitOps, and application deployment before implementing cluster-level redundancy.

**Decision:**
Deploy a **single EKS cluster** named `dev` for the initial development phase. Blue/Green cluster separation will be introduced later once:
- Applications are deployed and stable
- GitOps workflows are validated
- Upgrade procedures are understood
- Cost implications for a second cluster are justified

This follows a **progressive enhancement** pattern common in enterprise platforms where redundancy is added after functional stability.

### Cluster Design Specifications

| Attribute | Decision | Rationale |
|-----------|----------|-----------|
| **Cluster name** | `dev` | Single cluster, environment-scoped |
| **Endpoint access** | Private | Nodes in private subnets; no public endpoint; accessed via VPC endpoints or VPN |
| **Kubernetes version** | 1.30 (latest supported by AWS provider) | Balance of features and stability |
| **Control plane logging** | All types enabled (api, audit, authenticator, controllerManager, scheduler) | Essential for debugging and security auditing |
| **Secrets encryption** | KMS (EBS key from KMS module) | Encrypt etcd at rest |
| **Cluster IP family** | IPv4 | Simplest; IPv6 adds complexity without immediate benefit |
| **Node placement** | Private app subnets (3 AZs) | No public IPs on nodes; access via VPC endpoints |
| **Node group type** | Managed node groups (initial), Karpenter (later) | Managed groups for simplicity; Karpenter for flexibility |
| **Node sizing (dev)** | t3.medium (x3, min 2, max 6) | Cost-optimized for development; sufficient for initial workloads |
| **Node purchasing** | On-Demand (dev) | Spot for cost optimization added in later phases |
| **EBS encryption** | KMS (EBS key) | Encryption at rest for all volumes |
| **Add-ons** | CoreDNS, kube-proxy, vpc-cni, EBS CSI driver | Essential cluster services |
| **OIDC provider** | Created per cluster | Required for IRSA |

### Module Design

Create a single parameterized `eks` module that accepts:
- `cluster_name`, `cluster_version`, `vpc_id`, `subnet_ids`, `security_group_ids`
- `cluster_role_arn`, `node_role_arn`, `kms_key_arn`
- `endpoint_private_access`, `endpoint_public_access`
- `enabled_cluster_log_types`

The module will output:
- `cluster_id`, `cluster_arn`, `cluster_endpoint`
- `cluster_certificate_authority`
- `oidc_provider_arn`, `oidc_provider_url`
- `node_security_group_id`
- `cluster_primary_security_group_id`

### Managed Node Groups Module Design

Separate module to avoid bloating the EKS module:
- `cluster_name`, `node_role_arn`, `subnet_ids`
- `node_group_name`, `instance_types`, `scaling_config`
- `disk_size`, `kms_key_arn`, `labels`, `tags`

### IAM Module Extension

The existing IAM module already has conditional resources for the EBS CSI driver role. Once the EKS module creates the OIDC provider, the IAM module needs to be re-invoked with:
- `eks_oidc_provider_arn` — from EKS module output
- `eks_cluster_name` — from EKS module output

### Deployment Order

```
Step 1: Create EKS module     → terraform apply (cluster + OIDC)
Step 2: Create node groups     → terraform apply (nodes join cluster)
Step 3: Update IAM module      → terraform apply (EBS CSI IRSA role)
Step 4: Configure kubectl      → aws eks update-kubeconfig
Step 5: Validate cluster       → kubectl get nodes, pods
Step 6: Install EBS CSI driver → Helm chart (or Terraform)
Step 7: Deploy ArgoCD          → Phase 4
```

**Alternatives Considered:**
- Immediate Blue/Green deployment — rejected; doubles cost during development, adds debugging complexity, premature optimization
- Public endpoint access — rejected; security best practice is private clusters; access via VPC/SSM/bastion
- Spot instances for dev — rejected; Spot interruption causes instability during development; reserved for later optimization
- Single combined EKS+node module — rejected; separation allows independent lifecycle management (e.g., replacing node groups without touching cluster)

**Pros:**
- Faster time to working cluster
- Lower initial AWS cost (~$75/month vs ~$150/month for two clusters)
- Simpler debugging during early phases
- Follows progressive enhancement pattern

**Cons:**
- Cluster upgrades will require application downtime until Blue/Green is implemented
- No cluster-level DR until second cluster is deployed
- Need to refactor Route53 and application deployment later when splitting clusters

**Operational Impact:**
- Single kubeconfig for development
- Simplified node group management
- Easier integration testing for application teams
- Migration to Blue/Green later requires: new cluster deployment, data sync, traffic switch testing

**Security Implications:**
- Private cluster endpoint prevents public API exposure
- All traffic flows through VPC endpoints
- KMS encryption protects etcd and EBS volumes
- IRSA enables workload-level IAM isolation from day one
- Single cluster means all workloads share the same control plane — namespace isolation and network policies mitigate this risk

**Future Migration Path to Blue/Green:**
1. Deploy green cluster using same module with `cluster_name = "green"`
2. Create Route53 records for weighted routing
3. Replicate applications via ArgoCD
4. Test traffic shifting
5. Switch production traffic
6. Decommission old cluster or keep as standby

This design ensures the single cluster is a stepping stone, not a dead end.
