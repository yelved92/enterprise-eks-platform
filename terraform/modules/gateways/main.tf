# =============================================================================
# Gateways Module - Main Resources
# =============================================================================
# Creates Internet Gateway and NAT Instance for VPC internet access.
# -----------------------------------------------------------------------------

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
# NAT Instance - AMI (Amazon Linux 2 HVM + user_data for NAT)
# ------------------------------------------------------------------------------
data "aws_ami" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ------------------------------------------------------------------------------
# Security Group for NAT Instance
# ------------------------------------------------------------------------------
resource "aws_security_group" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  name_prefix = "${var.name}-nat-instance-"
  description = "Security group for NAT Instance"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-nat-instance"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "nat_instance_http" {
  for_each = var.enable_nat_instance ? { for idx, cidr in var.private_subnet_cidrs : idx => cidr } : {}

  security_group_id = aws_security_group.nat_instance[0].id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "nat_instance_https" {
  for_each = var.enable_nat_instance ? { for idx, cidr in var.private_subnet_cidrs : idx => cidr } : {}

  security_group_id = aws_security_group.nat_instance[0].id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "nat_instance_ssh" {
  count = var.enable_nat_instance ? 1 : 0

  security_group_id = aws_security_group.nat_instance[0].id
  cidr_ipv4         = var.management_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH from management CIDR"
}

resource "aws_vpc_security_group_egress_rule" "nat_instance_egress" {
  count = var.enable_nat_instance ? 1 : 0

  security_group_id = aws_security_group.nat_instance[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

# ------------------------------------------------------------------------------
# Elastic IP for NAT Instance
# ------------------------------------------------------------------------------
resource "aws_eip" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  domain = "vpc"

  tags = merge(
    {
      Name        = "${var.name}-nat-instance-eip"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# NAT Instance (t3.micro)
# ------------------------------------------------------------------------------
resource "aws_instance" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  ami                    = data.aws_ami.nat_instance[0].id
  instance_type          = var.nat_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.nat_instance[0].id]
  source_dest_check      = false

  user_data = <<-EOF
    #!/bin/bash
    # Enable IP forwarding
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p

    # Configure NAT iptables rules
    /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # Save rules for persistence across reboot
    /sbin/iptables-save > /etc/sysconfig/iptables
  EOF

  tags = merge(
    {
      Name        = "${var.name}-nat-instance"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Associate EIP after instance is created
resource "aws_eip_association" "nat_instance" {
  count = var.enable_nat_instance ? 1 : 0

  instance_id   = aws_instance.nat_instance[0].id
  allocation_id = aws_eip.nat_instance[0].id
}