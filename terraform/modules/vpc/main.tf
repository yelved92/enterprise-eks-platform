# =============================================================================
# VPC Module - Main Resources
# =============================================================================
# Core VPC resource with DNS support, IPv4 CIDR, and optional IPv6.
# -----------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    {
      Name        = var.name
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# IPv6 CIDR block (optional)
# ------------------------------------------------------------------------------
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count = var.secondary_cidrs != null ? length(var.secondary_cidrs) : 0

  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidrs[count.index]
}

# ------------------------------------------------------------------------------
# VPC Flow Logs (optional - recommended for production)
# ------------------------------------------------------------------------------
resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.name}-vpc-flow-logs"
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc-flow-logs/${var.name}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    {
      Name = "${var.name}-vpc-flow-logs"
    },
    var.tags
  )
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}