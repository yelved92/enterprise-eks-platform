# =============================================================================
# Gateways Module - Main Resources
# =============================================================================
# Creates Internet Gateway and NAT Gateways for VPC internet access.
# -----------------------------------------------------------------------------

locals {
  # Number of NAT Gateways to create
  nat_gw_count = var.single_nat_gateway ? min(1, length(var.public_subnet_ids)) : length(var.public_subnet_ids)
}

# ------------------------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  count = var.enable_igw ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-igw"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Elastic IPs for NAT Gateways
# ------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? local.nat_gw_count : 0

  domain = "vpc"

  tags = merge(
    {
      Name        = "${var.name}-nat-eip-${count.index}"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags,
    var.eip_tags
  )
}

# ------------------------------------------------------------------------------
# NAT Gateways
# ------------------------------------------------------------------------------
resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? local.nat_gw_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  # Ensure Internet Gateway is created first
  depends_on = [aws_internet_gateway.this]

  tags = merge(
    {
      Name        = "${var.name}-nat-gw-${count.index}"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags,
    var.nat_gateway_tags
  )
}