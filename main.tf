terraform {
  cloud {
    organization = "thew4yew"

    workspaces {
      name = "mc-cloudflare-infra"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "cloudflare_zones" "domain" {
  filter {
    name = local.main_site_domain
  }
}

resource "cloudflare_record" "site_cname" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = local.main_site_domain
  value   = var.static_site_url
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "www"
  value   = local.main_site_domain
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "star" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "*"
  value   = local.main_site_domain
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "azure_validation" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "@"
  value   = "b86yxrk5xl5pd0r83p7rwrhhbf3jbfbm"   # Remove me!!
  type    = "TXT"

}

resource "cloudflare_page_rule" "https" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  target  = "*.${local.main_site_domain}/*"
  actions {
    always_use_https = true
  }
}
