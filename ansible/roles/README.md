# Ansible Roles

This directory contains Ansible roles for the EKS platform.

## Role Structure

Each role follows the standard Ansible role directory layout:

```
roles/
├── role_name/
│   ├── tasks/          # Main tasks
│   ├── handlers/       # Handlers (restart services, etc.)
│   ├── templates/      # Jinja2 templates
│   ├── files/          # Static files
│   ├── vars/           # Role-specific variables
│   ├── defaults/       # Default variables
│   ├── meta/           # Role metadata and dependencies
│   └── README.md       # Role documentation
```

## Planned Roles

| Role | Purpose |
|------|---------|
| `bootstrap` | Pre-Terraform environment setup |
| `kubectl-setup` | Configure kubectl for cluster access |
| `cluster-validation` | Post-deployment cluster health checks |
| `dr-orchestration` | Disaster recovery failover workflows |
| `upgrade-workflow` | Cluster and component upgrade orchestration |

## Usage

Roles are referenced in playbooks:

```yaml
- name: Bootstrap environment
  hosts: bootstrap
  roles:
    - role: bootstrap
      vars:
        environment: dev
```