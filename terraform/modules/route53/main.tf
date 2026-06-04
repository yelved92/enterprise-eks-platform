# =============================================================================
# Route53 Module - Main Resources
# =============================================================================
# Creates a Route53 public hosted zone and DNS records for the domain.
# After applying, update your domain registrar's nameservers to the
# values output by this module.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Hosted Zone
# ------------------------------------------------------------------------------
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(
    {
      Name        = var.domain_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# ArgoCD DNS Record (NLB alias)
# ------------------------------------------------------------------------------
resource "aws_route53_record" "argocd" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "argocd.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.nginx_nlb_dns_name
    zone_id                = var.nginx_nlb_zone_id
    evaluate_target_health = true
  }
}

# ------------------------------------------------------------------------------
# Root Domain A Record (NLB alias) — optional
# ------------------------------------------------------------------------------
resource "aws_route53_record" "root" {
  count = var.create_root_record ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.nginx_nlb_dns_name
    zone_id                = var.nginx_nlb_zone_id
    evaluate_target_health = true
  }
}