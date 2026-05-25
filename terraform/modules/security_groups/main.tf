# =============================================================================
# Security Groups Module - Main Resources
# =============================================================================
# Creates baseline security groups for the EKS platform: ALB, cluster,
# node groups, internal services, and data layer.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# ALB / Ingress Security Group (public-facing)
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Security group for ALB / ingress controller"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-alb"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# HTTPS from internet
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count = var.enable_https_ingress ? 1 : 0

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from internet"
}

# HTTP from internet (redirect to HTTPS)
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from internet (redirect to HTTPS)"
}

# ALB egress to nodes
resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "Egress to VPC"
}

# ------------------------------------------------------------------------------
# EKS Cluster Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "${var.name}-eks-cluster"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-eks-cluster"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Cluster API server access from node groups and within VPC
resource "aws_vpc_security_group_ingress_rule" "cluster_api_vpc" {
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Kubernetes API from VPC"
}

# Cluster API server access from node security group
resource "aws_vpc_security_group_egress_rule" "cluster_egress" {
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Cluster egress to all"
}

# ------------------------------------------------------------------------------
# EKS Node Group Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "nodes" {
  name        = "${var.name}-eks-nodes"
  description = "Security group for EKS managed node groups"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name                                      = "${var.name}-eks-nodes"
      Environment                               = var.name
      ManagedBy                                 = "terraform"
      "kubernetes.io/cluster/${var.name}"       = "owned"
    },
    var.tags
  )
}

# Node to node communication (all ports/protocols for Kubernetes)
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "Node to node communication"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_self_udp" {
  security_group_id = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "udp"
  description       = "Node to node UDP communication"
}

# Node communication within VPC
resource "aws_vpc_security_group_ingress_rule" "nodes_vpc" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "Node communication within VPC"
}

# Node egress
resource "aws_vpc_security_group_egress_rule" "nodes_egress" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Node egress to all"
}

# ------------------------------------------------------------------------------
# Internal Service Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "internal_services" {
  name        = "${var.name}-internal-services"
  description = "Security group for internal service communication"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-internal-services"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Allow all internal traffic within the security group
resource "aws_vpc_security_group_ingress_rule" "internal_self" {
  security_group_id = aws_security_group.internal_services.id
  referenced_security_group_id = aws_security_group.internal_services.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "Internal service communication"
}

# ------------------------------------------------------------------------------
# Data Layer Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "data" {
  name        = "${var.name}-data"
  description = "Security group for data layer (RDS, ElastiCache, etc.)"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-data"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Allow traffic from node groups and internal services to data layer
resource "aws_vpc_security_group_ingress_rule" "data_from_nodes" {
  security_group_id = aws_security_group.data.id
  referenced_security_group_id = aws_security_group.nodes.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "Data access from nodes"
}

resource "aws_vpc_security_group_ingress_rule" "data_from_internal" {
  security_group_id = aws_security_group.data.id
  referenced_security_group_id = aws_security_group.internal_services.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "Data access from internal services"
}