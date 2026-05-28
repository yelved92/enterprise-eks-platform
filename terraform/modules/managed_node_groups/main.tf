# =============================================================================
# Managed Node Groups Module - Main Resources
# =============================================================================
# Creates EKS managed node groups with KMS encryption, private subnets,
# and configurable scaling. Designed for cost-optimized dev environments
# with easy production scaling.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Managed Node Group - Primary (On-Demand)
# ------------------------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn

  subnet_ids = var.subnet_ids

  instance_types = var.instance_types
  capacity_type  = var.use_spot ? "SPOT" : "ON_DEMAND"
  version       = var.cluster_version

  # disk_size is intentionally omitted: when launch_template is used, EBS
  # configuration (size, type, IOPS, KMS) comes from the launch template.
  # Setting both raises a conflict warning from the EKS API.

  scaling_config {
    desired_size = var.scaling_desired_size
    max_size     = var.scaling_max_size
    min_size     = var.scaling_min_size
  }

  # KMS encryption for EBS volumes attached to nodes
  launch_template {
    name    = aws_launch_template.this.name
    version = aws_launch_template.this.latest_version
  }

  # Update configuration for rolling updates
  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  # NOTE: well-known labels like topology.kubernetes.io/zone are reserved and
  # set automatically by the kubelet. We only set non-reserved labels here.
  labels = merge(
    {
      "node.kubernetes.io/role"      = "worker"
      "node.kubernetes.io/lifecycle" = var.use_spot ? "spot" : "on-demand"
    },
    var.labels
  )

  tags = merge(
    {
      Name                                      = var.node_group_name
      Environment                               = var.cluster_name
      ManagedBy                                 = "terraform"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    var.tags
  )

  # Ensure cluster is fully created before adding nodes
  depends_on = [var.cluster_depends_on]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

# ------------------------------------------------------------------------------
# Launch Template (for KMS EBS encryption)
# ------------------------------------------------------------------------------
resource "aws_launch_template" "this" {
  name_prefix   = "${var.node_group_name}-"
  description   = "Launch template for EKS managed node group ${var.node_group_name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        Name                                      = var.node_group_name
        Environment                               = var.cluster_name
        ManagedBy                                 = "terraform"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      },
      var.tags
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      {
        Name        = "${var.node_group_name}-ebs"
        Environment = var.cluster_name
        ManagedBy   = "terraform"
      },
      var.tags
    )
  }

  tags = merge(
    {
      Name        = "${var.node_group_name}-lt"
      Environment = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}