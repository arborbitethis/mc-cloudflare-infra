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

##################################################
#   courter.dev
##################################################

data "cloudflare_zones" "courterdev" {
  filter {
    name = local.courterdev_domain
  }
}

# Rules to handle traffic from courter.dev domain to azure static site
resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zones.courterdev.zones[0].id
  name    = "www"
  value   = var.static_site_url
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_page_rule" "https" {
  zone_id = data.cloudflare_zones.courterdev.zones[0].id
  target  = "*.${local.courterdev_domain}/*"
  actions {
    always_use_https = true
  }
}
