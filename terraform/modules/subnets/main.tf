# =============================================================================
# Subnets Module - Main Resources
# =============================================================================
# Creates public, private app, and private data subnets across multiple AZs.
# -----------------------------------------------------------------------------

locals {
  subnet_types = keys(var.cidr_blocks)
}

# ------------------------------------------------------------------------------
# Dynamic Subnet Creation
# ------------------------------------------------------------------------------
resource "aws_subnet" "this" {
  for_each = {
    for entry in flatten([
      for type, cidrs in var.cidr_blocks : [
        for idx, cidr in cidrs : {
          key      = "${type}-${idx}"
          type     = type
          az_index = idx
          cidr     = cidr
          az       = var.availability_zones[idx]
        }
      ]
    ]) : entry.key => entry
  }

  vpc_id            = var.vpc_id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  # Only assign public IPs to public subnets
  map_public_ip_on_launch = each.value.type == "public" ? var.map_public_ip_on_launch : false

  tags = merge(
    {
      Name        = "${var.name}-${each.value.type}-${each.value.az_index}"
      Type        = each.value.type
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags,
    each.value.type == "public" ? var.public_subnet_tags : {},
    each.value.type == "private_app" ? var.private_app_subnet_tags : {},
    each.value.type == "private_data" ? var.private_data_subnet_tags : {}
  )
}

# ------------------------------------------------------------------------------
# EKS Cluster Tags (for subnets to auto-discover)
# ------------------------------------------------------------------------------
# Note: The kubernetes.io/cluster/<cluster-name> tags are managed separately
# in the EKS module since the cluster name is not known at VPC creation time.
