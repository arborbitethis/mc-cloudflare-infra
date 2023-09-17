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

resource "cloudflare_record" "c_www" {
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

##################################################
#   evilfrenchie.com

#   setting up evilfrenchie dns to support redirects to courter.dev
##################################################
data "cloudflare_zones" "evilfrenchie" {
  filter {
    name = local.evilfrenchie_domain
  }
}

resource "cloudflare_record" "ef_root" {
  zone_id = data.cloudflare_zones.evilfrenchie.zones[0].id
  name    = local.evilfrenchie_domain
  value   = "evilfrenchie.invalid"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "ef_www" {
  zone_id = data.cloudflare_zones.evilfrenchie.zones[0].id
  name    = "www"
  value   = "evilfrenchie.invalid"
  type    = "CNAME"
  proxied = false
}


##################################################
#   twentyfivecents.cc
#   setting up twentyfivecents dns to support redirects to courter.dev
##################################################

data "cloudflare_zones" "twentyfivecents" {
  filter {
    name = local.twentyfivecents_domain
  }
}

resource "cloudflare_record" "tfc_root" {
  zone_id = data.cloudflare_zones.twentyfivecents.zones[0].id
  name    = local.twentyfivecents_domain
  value   = "twentyfivecents.invalid"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "tfc_www" {
  zone_id = data.cloudflare_zones.twentyfivecents.zones[0].id
  name    = "www"
  value   = "twentyfivecents.invalid"
  type    = "CNAME"
  proxied = false
}

##################################################
#   Bulk redirect for evilfrenchie.com and twentyfivecents.cc to courter.dev 
##################################################

# create list
resource "cloudflare_list" "redir_list" {
  account_id  = var.cloudflare_account_id
  name        = "courterdev_redirect_list"
  description = "redirects to courter.dev"
  kind        = "redirect"

  item {
    value {
      redirect {
        source_url            = local.evilfrenchie_domain
        target_url            = "https://www.${local.courterdev_domain}"
        include_subdomains    = "disabled"
        subpath_matching      = "disabled"
        status_code           = 301
        preserve_query_string = "disabled"
        preserve_path_suffix  = "disabled"
      }
    }
  }

  item {
    value {
      redirect {
        source_url            = "www.${local.evilfrenchie_domain}"
        target_url            = "https://www.${local.courterdev_domain}"
        include_subdomains    = "disabled"
        subpath_matching      = "disabled"
        status_code           = 301
        preserve_query_string = "disabled"
        preserve_path_suffix  = "disabled"
      }
    }
  }

  item {
    value {
      redirect {
        source_url            = local.twentyfivecents_domain
        target_url            = "https://www.${local.courterdev_domain}"
        include_subdomains    = "disabled"
        subpath_matching      = "disabled"
        status_code           = 301
        preserve_query_string = "disabled"
        preserve_path_suffix  = "disabled"
      }
    }
  }

  item {
    value {
      redirect {
        source_url            = "www.${local.twentyfivecents_domain}"
        target_url            = "https://www.${local.courterdev_domain}"
        include_subdomains    = "disabled"
        subpath_matching      = "disabled"
        status_code           = 301
        preserve_query_string = "disabled"
        preserve_path_suffix  = "disabled"
      }
    }
  }
}


# Redirects based on the list
resource "cloudflare_ruleset" "redirect_from_list" {
  account_id  = var.cloudflare_account_id
  name        = "courterdev_redirect_ruleset"
  description = "Redirect ruleset to courterdev domain"
  kind        = "root"
  phase       = "http_request_redirect"

  rules {
    action = "redirect"
    action_parameters {
      from_list {
        name = "courterdev_redirect_list"
        key  = "http.request.full_uri"
      }
    }
    expression  = "http.request.full_uri in $courterdev_redirect_list"
    description = "Apply redirects from courterdev_redirect_list"
    enabled     = true
  }
}

