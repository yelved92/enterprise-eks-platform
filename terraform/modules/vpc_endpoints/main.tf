# =============================================================================
# VPC Endpoints Module - Main Resources
# =============================================================================
# Creates Gateway and Interface VPC Endpoints for private subnet access to
# AWS services without traversing the internet/NAT Gateway.
# -----------------------------------------------------------------------------

data "aws_region" "current" {}
data "aws_vpc_endpoint_service" "s3" {
  count        = var.enable_s3_gateway_endpoint ? 1 : 0
  service      = "s3"
  service_type = "Gateway"
}

data "aws_vpc_endpoint_service" "dynamodb" {
  count        = var.enable_dynamodb_gateway_endpoint ? 1 : 0
  service      = "dynamodb"
  service_type = "Gateway"
}

# ------------------------------------------------------------------------------
# Gateway Endpoints (S3, DynamoDB)
# ------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.enable_s3_gateway_endpoint ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = data.aws_vpc_endpoint_service.s3[0].service_name

  tags = merge(
    {
      Name        = "${var.name}-s3-gateway"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "dynamodb_gateway" {
  count = var.enable_dynamodb_gateway_endpoint ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = data.aws_vpc_endpoint_service.dynamodb[0].service_name

  tags = merge(
    {
      Name        = "${var.name}-dynamodb-gateway"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# Gateway endpoint associations with route tables
resource "aws_vpc_endpoint_route_table_association" "s3_private_app" {
  count = var.enable_s3_gateway_endpoint ? length(var.private_app_route_table_ids) : 0

  route_table_id  = var.private_app_route_table_ids[count.index]
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway[0].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private_data" {
  count = var.enable_s3_gateway_endpoint ? length(var.private_data_route_table_ids) : 0

  route_table_id  = var.private_data_route_table_ids[count.index]
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway[0].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private_app" {
  count = var.enable_dynamodb_gateway_endpoint ? length(var.private_app_route_table_ids) : 0

  route_table_id  = var.private_app_route_table_ids[count.index]
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb_gateway[0].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private_data" {
  count = var.enable_dynamodb_gateway_endpoint ? length(var.private_data_route_table_ids) : 0

  route_table_id  = var.private_data_route_table_ids[count.index]
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb_gateway[0].id
}

# ------------------------------------------------------------------------------
# Interface Endpoints (ECR, SSM, KMS, Logs, STS)
# ------------------------------------------------------------------------------
locals {
  interface_endpoints = {
    ecr_api = {
      enable  = var.enable_ecr_api_endpoint
      service = "ecr.api"
    }
    ecr_dkr = {
      enable  = var.enable_ecr_dkr_endpoint
      service = "ecr.dkr"
    }
    ssm = {
      enable  = var.enable_ssm_endpoint
      service = "ssm"
    }
    kms = {
      enable  = var.enable_kms_endpoint
      service = "kms"
    }
    logs = {
      enable  = var.enable_logs_endpoint
      service = "logs"
    }
    sts = {
      enable  = var.enable_sts_endpoint
      service = "sts"
    }
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = { for k, v in local.interface_endpoints : k => v if v.enable }

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_app_subnet_ids
  security_group_ids  = var.security_group_id != null ? [var.security_group_id] : []
  private_dns_enabled = true

  tags = merge(
    {
      Name        = "${var.name}-${each.key}"
      Environment = var.name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
