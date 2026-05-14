# =============================================================================
# Dev Environment - Main Configuration
# =============================================================================
# Wires together all Terraform modules for the dev environment.
# Uses cost-optimized single NAT Gateway configuration for lab/dev.
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
}

# ------------------------------------------------------------------------------
# VPC Module
# ------------------------------------------------------------------------------
module "vpc" {
  source = "../modules/vpc"

  name                  = var.environment
  cidr_block            = var.vpc_cidr
  enable_dns_hostnames  = true
  enable_dns_support    = true
  enable_flow_logs      = var.enable_flow_logs
  flow_logs_retention_days = 30
  tags                  = var.tags
}

# ------------------------------------------------------------------------------
# Subnets Module
# ------------------------------------------------------------------------------
module "subnets" {
  source = "../modules/subnets"

  name               = var.environment
  vpc_id             = module.vpc.vpc_id
  availability_zones = var.availability_zones
  cidr_blocks        = local.subnet_cidrs
  tags               = var.tags
}

# ------------------------------------------------------------------------------
# Gateways Module
# ------------------------------------------------------------------------------
module "gateways" {
  source = "../modules/gateways"

  name                = var.environment
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.subnets.public_subnet_ids
  single_nat_gateway  = var.single_nat_gateway
  enable_nat_gateway  = true
  enable_igw          = true
  tags                = var.tags
}

# ------------------------------------------------------------------------------
# Routing Module
# ------------------------------------------------------------------------------
module "routing" {
  source = "../modules/routing"

  name                      = var.environment
  vpc_id                    = module.vpc.vpc_id
  igw_id                    = module.gateways.igw_id
  nat_gateway_ids           = module.gateways.nat_gateway_ids
  public_subnet_ids         = module.subnets.public_subnet_ids
  private_app_subnet_ids    = module.subnets.private_app_subnet_ids
  private_data_subnet_ids   = module.subnets.private_data_subnet_ids
  single_nat_gateway        = var.single_nat_gateway
  create_private_route_tables = true
  tags                      = var.tags
}

# ------------------------------------------------------------------------------
# Security Groups Module
# ------------------------------------------------------------------------------
module "security_groups" {
  source = "../modules/security_groups"

  name               = var.environment
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  enable_https_ingress = true
  tags               = var.tags
}

# ------------------------------------------------------------------------------
# Network ACLs Module
# ------------------------------------------------------------------------------
module "network_acls" {
  source = "../modules/network_acls"

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
  source = "../modules/kms"

  name                   = var.environment
  enable_key_rotation    = true
  deletion_window_in_days = 30
  enable_default_ebs_key = true
  tags                   = var.tags
}

# ------------------------------------------------------------------------------
# IAM Module
# ------------------------------------------------------------------------------
module "iam" {
  source = "../modules/iam"

  name = var.environment
  tags = var.tags

  # EBS CSI role will be wired after EKS cluster + OIDC provider creation
  eks_cluster_name     = null
  eks_oidc_provider_arn = null
}

# ------------------------------------------------------------------------------
# VPC Endpoints Module
# ------------------------------------------------------------------------------
module "vpc_endpoints" {
  source = "../modules/vpc_endpoints"

  name                       = var.environment
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_ids     = module.subnets.private_app_subnet_ids
  private_data_subnet_ids    = module.subnets.private_data_subnet_ids
  private_app_route_table_ids = module.routing.private_app_route_table_ids
  private_data_route_table_ids = module.routing.private_data_route_table_ids
  security_group_id          = module.security_groups.cluster_security_group_id
  enable_s3_gateway_endpoint   = true
  enable_dynamodb_gateway_endpoint = true
  enable_ecr_api_endpoint     = true
  enable_ecr_dkr_endpoint     = true
  enable_ssm_endpoint         = true
  enable_kms_endpoint         = true
  enable_logs_endpoint        = true
  enable_sts_endpoint         = true
  tags                        = var.tags
}

# ------------------------------------------------------------------------------
# Outputs (convenience)
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