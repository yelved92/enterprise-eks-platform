# =============================================================================
# Routing Module - Main Resources
# =============================================================================
# Creates route tables and subnet associations for public, private app, and
# private data subnets. Supports single or multi-NAT Gateway configurations.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Route Table
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  count = length(var.public_subnet_ids) > 0 ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-public"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_route" "public_internet_access" {
  count = length(var.public_subnet_ids) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_ids)

  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public[0].id
}

# ------------------------------------------------------------------------------
# Private App Route Tables
# ------------------------------------------------------------------------------
resource "aws_route_table" "private_app" {
  count = var.create_private_route_tables ? length(var.private_app_subnet_ids) : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-private-app-${count.index}"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_route" "private_app_nat" {
  count = var.create_private_route_tables ? length(var.private_app_subnet_ids) : 0

  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? var.nat_gateway_ids[0] : var.nat_gateway_ids[count.index]
}

resource "aws_route_table_association" "private_app" {
  count = var.create_private_route_tables ? length(var.private_app_subnet_ids) : 0

  subnet_id      = var.private_app_subnet_ids[count.index]
  route_table_id = aws_route_table.private_app[count.index].id
}

# ------------------------------------------------------------------------------
# Private Data Route Tables
# ------------------------------------------------------------------------------
resource "aws_route_table" "private_data" {
  count = var.create_private_route_tables ? length(var.private_data_subnet_ids) : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-private-data-${count.index}"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_route" "private_data_nat" {
  count = var.create_private_route_tables ? length(var.private_data_subnet_ids) : 0

  route_table_id         = aws_route_table.private_data[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? var.nat_gateway_ids[0] : var.nat_gateway_ids[length(var.private_app_subnet_ids) + count.index]
}

resource "aws_route_table_association" "private_data" {
  count = var.create_private_route_tables ? length(var.private_data_subnet_ids) : 0

  subnet_id      = var.private_data_subnet_ids[count.index]
  route_table_id = aws_route_table.private_data[count.index].id
}