resource "cloudflare_record" "app_dns_record" {
  for_each = toset(var.cname_labels)

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "CNAME"
  content = module.alb.alb_dns_name

  proxied = var.cloudflare_proxied
  ttl     = var.cloudflare_proxied ? 1 : 3600
}