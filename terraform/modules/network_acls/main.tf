# =============================================================================
# Network ACLs Module - Main Resources
# =============================================================================
# Creates stateless network ACLs for public, private app, and private data
# subnets. NACLs provide an additional layer of security at the subnet level.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Subnet NACL
# ------------------------------------------------------------------------------
resource "aws_network_acl" "public" {
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

resource "aws_network_acl_rule" "public_ingress_http" {
  count = length(var.public_subnet_ids) > 0 ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_ingress_https" {
  count = length(var.public_subnet_ids) > 0 ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_ingress_ephemeral" {
  count = length(var.public_subnet_ids) > 0 ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_egress_all" {
  count = length(var.public_subnet_ids) > 0 ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# ------------------------------------------------------------------------------
# Private Subnet NACL (Applied to both private app and data)
# ------------------------------------------------------------------------------
resource "aws_network_acl" "private" {
  count = length(var.private_app_subnet_ids) > 0 ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-private"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_network_acl_rule" "private_ingress_vpc" {
  count = length(var.private_app_subnet_ids) > 0 ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_egress_vpc" {
  count = length(var.private_app_subnet_ids) > 0 ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_egress_internet" {
  count = length(var.private_app_subnet_ids) > 0 ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# ------------------------------------------------------------------------------
# Subnet-to-NACL Associations
# ------------------------------------------------------------------------------
resource "aws_network_acl_association" "public" {
  count = length(var.public_subnet_ids)

  subnet_id      = var.public_subnet_ids[count.index]
  network_acl_id = aws_network_acl.public[0].id
}

resource "aws_network_acl_association" "private_app" {
  count = length(var.private_app_subnet_ids)

  subnet_id      = var.private_app_subnet_ids[count.index]
  network_acl_id = aws_network_acl.private[0].id
}

resource "aws_network_acl_association" "private_data" {
  count = length(var.private_data_subnet_ids)

  subnet_id      = var.private_data_subnet_ids[count.index]
  network_acl_id = aws_network_acl.private[0].id
}