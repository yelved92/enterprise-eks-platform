# =============================================================================
# Dev Environment - Main Configuration
# =============================================================================
# Wires together all Terraform modules for the dev environment.
# Uses cost-optimized NAT Instance instead of NAT Gateway for lab/dev.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Subnet CIDR Allocation (3 AZs)
# ------------------------------------------------------------------------------
locals {
  subnet_cidrs = {
    public       = ["10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"]
    private_app  = ["10.0.32.0/21", "10.0.40.0/21", "10.0.48.0/21"]
    private_data = ["10.0.64.0/21", "10.0.72.0/21", "10.0.80.0/21"]
  }

  # Flattened list of all private subnet CIDRs (for NAT Instance security group)
  private_subnet_cidrs = flatten([
    for type, cidrs in local.subnet_cidrs : cidrs
    if type != "public"
  ])
}

# ------------------------------------------------------------------------------
# VPC Module
# ------------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  name                     = var.environment
  cidr_block               = var.vpc_cidr
  enable_dns_hostnames     = true
  enable_dns_support       = true
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = 30
  tags                     = var.tags
}

# ------------------------------------------------------------------------------
# Subnets Module
# ------------------------------------------------------------------------------
module "subnets" {
  source = "../../modules/subnets"

  name               = var.environment
  vpc_id             = module.vpc.vpc_id
  availability_zones = var.availability_zones
  cidr_blocks        = local.subnet_cidrs
  elbv2_cluster_name = var.environment
  tags               = var.tags
}

# ------------------------------------------------------------------------------
# Gateways Module
# ------------------------------------------------------------------------------
module "gateways" {
  source = "../../modules/gateways"

  name                 = var.environment
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.subnets.public_subnet_ids
  public_subnet_id     = module.subnets.public_subnet_ids[0]
  private_subnet_cidrs = local.private_subnet_cidrs
  enable_nat_instance  = true
  enable_igw           = true
  tags                 = var.tags
}

# ------------------------------------------------------------------------------
# Routing Module
# ------------------------------------------------------------------------------
module "routing" {
  source = "../../modules/routing"

  name                        = var.environment
  vpc_id                      = module.vpc.vpc_id
  igw_id                      = module.gateways.igw_id
  nat_instance_eni_id         = module.gateways.nat_instance_eni_id
  public_subnet_ids           = module.subnets.public_subnet_ids
  private_app_subnet_ids      = module.subnets.private_app_subnet_ids
  private_data_subnet_ids     = module.subnets.private_data_subnet_ids
  create_private_route_tables = true
  tags                        = var.tags
}

# ------------------------------------------------------------------------------
# Security Groups Module
# ------------------------------------------------------------------------------
module "security_groups" {
  source = "../../modules/security_groups"

  name                 = var.environment
  vpc_id               = module.vpc.vpc_id
  vpc_cidr_block       = module.vpc.vpc_cidr_block
  enable_https_ingress = true
  tags                 = var.tags
}

# ------------------------------------------------------------------------------
# Network ACLs Module
# ------------------------------------------------------------------------------
module "network_acls" {
  source = "../../modules/network_acls"

  name                    = var.environment
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr_block          = module.vpc.vpc_cidr_block
  public_subnet_ids       = module.subnets.public_subnet_ids
  private_app_subnet_ids  = module.subnets.private_app_subnet_ids
  private_data_subnet_ids = module.subnets.private_data_subnet_ids
  tags                    = var.tags
}

# ------------------------------------------------------------------------------
# KMS Module
# ------------------------------------------------------------------------------
module "kms" {
  source = "../../modules/kms"

  name                    = var.environment
  enable_key_rotation     = true
  deletion_window_in_days = 30
  enable_default_ebs_key  = true
  tags                    = var.tags
}

# ------------------------------------------------------------------------------
# IAM Module (base roles: cluster, nodes)
# ------------------------------------------------------------------------------
# Creates the EKS cluster IAM role and node instance role. These do NOT depend
# on the EKS cluster existing, so they are applied first and then consumed by
# the eks/managed_node_groups modules.
# ------------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  name = var.environment
  tags = var.tags
}

# ------------------------------------------------------------------------------
# VPC Endpoints Module
# ------------------------------------------------------------------------------
module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  name                             = var.environment
  vpc_id                           = module.vpc.vpc_id
  private_app_subnet_ids           = module.subnets.private_app_subnet_ids
  private_data_subnet_ids          = module.subnets.private_data_subnet_ids
  private_app_route_table_ids      = module.routing.private_app_route_table_ids
  private_data_route_table_ids     = module.routing.private_data_route_table_ids
  security_group_id                = module.security_groups.cluster_security_group_id
  enable_s3_gateway_endpoint       = true
  enable_dynamodb_gateway_endpoint = true
  # Interface endpoints disabled for cost optimization (NAT Instance handles routing)
  enable_s3_interface_endpoint = false
  enable_ec2_endpoint          = false
  enable_ecr_api_endpoint      = false
  enable_ecr_dkr_endpoint      = false
  enable_ssm_endpoint          = false
  enable_kms_endpoint          = false
  enable_logs_endpoint         = false
  enable_sts_endpoint          = false
  tags                         = var.tags
}

# ------------------------------------------------------------------------------
# EKS Cluster Module
# ------------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.environment
  cluster_version    = var.cluster_version
  cluster_role_arn   = module.iam.cluster_role_arn
  subnet_ids         = module.subnets.private_app_subnet_ids
  security_group_ids = [module.security_groups.cluster_security_group_id]
  kms_key_arn        = module.kms.kms_key_arn

  endpoint_private_access    = var.endpoint_private_access
  endpoint_public_access     = var.endpoint_public_access
  public_access_cidrs        = var.public_access_cidrs
  enabled_cluster_log_types  = var.enabled_cluster_log_types
  cluster_log_retention_days = var.cluster_log_retention_days
  ebs_csi_role_arn                    = module.iam_irsa.ebs_csi_role_arn

  tags = var.tags
}

# ------------------------------------------------------------------------------
# IAM IRSA Module (OIDC-dependent roles: EBS CSI, VPC CNI, etc.)
# ------------------------------------------------------------------------------
# Created AFTER module.eks so the OIDC issuer URL is known at plan time.
# Splitting this out of module.iam avoids the "count depends on unknown value"
# error — module.iam_irsa has no count gating on OIDC, it always creates
# its enabled roles, but it's only added to the graph downstream of module.eks.
# ------------------------------------------------------------------------------
module "iam_irsa" {
  source = "../../modules/iam_irsa"

  name              = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = replace(module.eks.oidc_provider_url, "https://", "")

  enable_ebs_csi_role                    = true
  enable_vpc_cni_role                    = true
  enable_cert_manager_role               = true
  enable_external_secrets_role           = true
  enable_load_balancer_controller_role   = true

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Managed Node Groups Module
# ------------------------------------------------------------------------------
module "node_group" {
  source = "../../modules/managed_node_groups"

  cluster_name    = module.eks.cluster_name
  cluster_version = var.cluster_version
  node_group_name = var.node_group_name
  node_role_arn   = module.iam.node_role_arn
  subnet_ids      = module.subnets.private_app_subnet_ids

  instance_types = var.node_group_instance_types
  disk_size      = var.node_group_disk_size

  kms_key_arn = module.kms.ebs_kms_key_arn

  scaling_desired_size = var.node_group_scaling_desired
  scaling_max_size     = var.node_group_scaling_max
  scaling_min_size     = var.node_group_scaling_min

  use_spot = var.use_spot_instances

  cluster_depends_on = [module.eks.cluster_id]

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Route53 Module — DNS for yelved.xyz
# ------------------------------------------------------------------------------
data "aws_lb" "kong_nlb" {
  tags = {
    "service.k8s.aws/stack" = "kong/kong-kong-proxy"
  }
}

module "route53" {
  source = "../../modules/route53"

  domain_name        = var.domain_name
  environment        = var.environment
  nginx_nlb_dns_name = data.aws_lb.kong_nlb.dns_name
  nginx_nlb_zone_id  = data.aws_lb.kong_nlb.zone_id
  tags               = var.tags
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.subnets.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = module.subnets.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "List of private data subnet IDs"
  value       = module.subnets.private_data_subnet_ids
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam.cluster_role_arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.iam.node_role_arn
}

output "kms_key_arn" {
  description = "ARN of the default KMS key"
  value       = module.kms.kms_key_arn
}

output "ebs_kms_key_arn" {
  description = "ARN of the EBS KMS key"
  value       = module.kms.ebs_kms_key_arn
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "The API server endpoint URL"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = module.eks.oidc_provider_url
}

output "load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IRSA role"
  value       = module.iam_irsa.load_balancer_controller_role_arn
}

output "eks_node_group_id" {
  description = "The ID of the managed node group"
  value       = module.node_group.node_group_id
}

output "eks_node_group_name" {
  description = "The name of the managed node group"
  value       = module.node_group.node_group_name
}


# ------------------------------------------------------------------------------
# ArgoCD Module � GitOps Deployment (Phase 4)
# ------------------------------------------------------------------------------
# Deploys ArgoCD into the EKS cluster using the Helm provider.
# The cluster must already exist before this module runs.
# Uses cluster-local service (ClusterIP) � no public exposure in Phase 4A.
# ------------------------------------------------------------------------------
# NOTE: The kubernetes and helm providers are configured in providers.tf and
# depend on module.eks. That implicit dependency ensures this module runs
# after the cluster exists.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# cert-manager, ClusterIssuer, and future add-ons are deployed via ArgoCD
# GitOps (see argocd/applications/) rather than Terraform. This follows the
# principle: Terraform manages AWS infrastructure, ArgoCD manages cluster apps.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Additional Outputs
# ------------------------------------------------------------------------------
output "cert_manager_role_arn" {
  description = "ARN of the cert-manager IRSA role for Route53 DNS-01 challenges"
  value       = module.iam_irsa.cert_manager_role_arn
}

output "hosted_zone_id" {
  description = "ID of the Route53 hosted zone for yelved.xyz"
  value       = module.route53.hosted_zone_id
}

output "auth_record_fqdn" {
  description = "FQDN of the Authentik DNS record"
  value       = module.route53.auth_record_fqdn
}

output "kong_record_fqdn" {
  description = "FQDN of the Kong proxy DNS record"
  value       = module.route53.kong_record_fqdn
}

output "grafana_record_fqdn" {
  description = "FQDN of the Grafana DNS record"
  value       = module.route53.grafana_record_fqdn
}

output "route53_name_servers" {
  description = "List of Route53 nameservers. Set these at your domain registrar (GoDaddy)."
  value       = module.route53.name_servers
}

output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IRSA role"
  value       = module.iam_irsa.external_secrets_role_arn
}

