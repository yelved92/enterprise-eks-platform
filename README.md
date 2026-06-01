# Enterprise-Grade AWS EKS Platform

> **A production-grade Kubernetes platform on AWS EKS with GitOps, observability, security hardening, service mesh, and disaster recovery.**

## Overview

This project implements a complete enterprise Kubernetes platform designed for production workloads. It demonstrates senior-level DevOps, SRE, and platform engineering practices including:

- **Infrastructure as Code** — Terraform with modular design
- **GitOps** — ArgoCD with app-of-apps pattern
- **Blue/Green Clusters** — Active/standby EKS clusters for zero-downtime upgrades and disaster recovery
- **Service Mesh** — Istio with mTLS, traffic shifting, canary deployments
- **Observability** — Prometheus, Grafana, Loki, Tempo, OpenTelemetry
- **Security Hardening** — Kyverno, Falco, Trivy, External Secrets, network policies
- **Disaster Recovery** — Velero, EBS snapshots, Route53 failover
- **CI/CD** — Automated pipelines with security scanning and policy validation

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Route53 (DNS)                      │
└──────────┬──────────────────────────┬────────────────┘
           │                          │
    ┌──────▼──────┐           ┌──────▼──────┐
    │ Blue Cluster │           │Green Cluster│
    │  (Active)    │           │ (Standby)   │
    └──────┬──────┘           └──────┬──────┘
           │                          │
    ┌──────▼──────────────────────────▼──────┐
    │           Shared Services               │
    │  - VPC / Networking                     │
    │  - Istio Control Plane                  │
    │  - Observability Stack                  │
    │  - Security Tooling                     │
    └─────────────────────────────────────────┘
```

## Repository Structure

```
├── terraform/          # Infrastructure as Code (Terraform modules + environments)
├── kubernetes/         # Kubernetes manifests
├── argocd/             # GitOps configuration (app-of-apps)
├── helm/               # Custom Helm charts
├── observability/      # Prometheus, Grafana, Loki, Tempo config
├── security/           # Kyverno, Falco, Trivy, policies
├── apps/               # Application manifests (OpenTelemetry Demo)
├── scripts/            # Utility scripts
├── docs/               # Documentation
├── diagrams/           # Architecture diagrams
├── runbooks/           # Operational runbooks
├── policies/           # Policy-as-code (OPA, Kyverno)
└── ansible/            # Configuration management
```

## Prerequisites

- AWS account with appropriate permissions
- Terraform 1.5+
- AWS CLI configured
- kubectl
- Helm 3+
- ArgoCD CLI (optional)
- Istio CLI (optional)

## Getting Started

See [docs/setup.md](docs/setup.md) for detailed setup instructions.

## Phases

This project is implemented incrementally:

| Phase | Component | Status |
|-------|-----------|--------|
| 1 | Project Initialization | ✅ Complete |
| 2 | Terraform Base Networking | ✅ Deployed |
| 3 | EKS Cluster Deployment | ✅ Deployed & Validated |
| 4 | GitOps with ArgoCD + OAuth SSO | 🔄 In Progress (Phase 4C) |
| 5 | Security Hardening | ⏳ Pending |
| 6 | Service Mesh (Istio) | ⏳ Pending |
| 7 | Observability Stack | ⏳ Pending |
| 8 | Application Deployment (OTel Demo) | 🔄 In Progress |
| 9 | CI/CD Pipelines | ⏳ Pending |
| 10 | Disaster Recovery | ⏳ Pending |
| 11 | Advanced Topics | ⏳ Pending |

## Project State

For session continuity and detailed project state, see:
- [docs/project-state.md](docs/project-state.md)
- [docs/progress-log.md](docs/progress-log.md)
- [docs/architecture-decisions.md](docs/architecture-decisions.md)
- [docs/todo.md](docs/todo.md)

## Contributing

This is a portfolio/learning project. Contributions and suggestions welcome.

## License

MIT