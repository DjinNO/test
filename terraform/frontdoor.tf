resource "azurerm_cdn_frontdoor_profile" "example" {
  name                = "MyFrontDoor"
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "example" {
  name                     = "afd-${lower(random_id.front_door_endpoint_name.hex)}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_cdn_frontdoor_origin_group" "example" {
  name                     = "MyOriginGroup"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "example" {
  name                          = "StaticContentOrigin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id

  enabled                        = true
  host_name                      = azurerm_storage_account.example.primary_blob_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_storage_account.example.primary_blob_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    private_link_target_id = azurerm_storage_account.example.id
    target_type            = "blob"
    request_message        = "Request access for Azure Front Door Private Link origin"
    location               = var.location
  }
}

resource "azurerm_cdn_frontdoor_route" "example" {
  name                          = "StaticRoute"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.example.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.example.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpsOnly"
  link_to_default_domain        = true
  https_redirect_enabled        = true
  lifecycle {
    ignore_changes = [cdn_frontdoor_rule_set_ids]
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "example" {
  name                     = "exampleruleset"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_cdn_frontdoor_rule" "example" {
  depends_on = [azurerm_cdn_frontdoor_origin_group.example, azurerm_cdn_frontdoor_origin.example]

  name                      = "examplerule"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.example.id
  order                     = 1
  behavior_on_match         = "Continue"

  actions {
    url_rewrite_action {
      source_pattern          = "/"
      destination             = "/static/index.html"
      preserve_unmatched_path = true
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "example" {
  name                     = "MyCustomDomain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
  host_name                = var.custom_domain_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}
