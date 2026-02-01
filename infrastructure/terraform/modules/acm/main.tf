resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name    = "${var.project_name}-cert"
    Project = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      content = dvo.resource_record_value
      type    = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = 60
  proxied = false
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  # Used trimsuffix to match the record names precisely as AWS expects them
  validation_record_fqdns = [for record in cloudflare_record.validation : trimsuffix(record.hostname, ".")]
}