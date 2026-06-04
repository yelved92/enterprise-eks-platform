# =============================================================================
# Route53 Module - Variables
# =============================================================================

variable "domain_name" {
  description = "Domain name for the Route53 hosted zone (e.g., yelved.xyz)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "nginx_nlb_dns_name" {
  description = "DNS name of the nginx-ingress NLB to point records to"
  type        = string
}

variable "nginx_nlb_zone_id" {
  description = "Canonical hosted zone ID of the nginx-ingress NLB"
  type        = string
}

variable "create_root_record" {
  description = "Create an A record for the root domain pointing to the NLB"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}