output "tenant_root_id" {
  description = "Tenant Root Management Group ID"
  value       = data.azurerm_management_group.tenant_root.id
}

output "platform_mg_id" {
  description = "Platform Management Group ID"
  value       = azurerm_management_group.platform.id
}

output "identity_mg_id" {
  description = "Identity Management Group ID"
  value       = azurerm_management_group.identity.id
}

output "connectivity_mg_id" {
  description = "Connectivity Management Group ID"
  value       = azurerm_management_group.connectivity.id
}

output "landing_zones_mg_id" {
  description = "Landing Zones Management Group ID"
  value       = azurerm_management_group.landing_zones.id
}

output "prod_mg_id" {
  description = "Prod Management Group ID"
  value       = azurerm_management_group.prod.id
}

output "nonprod_mg_id" {
  description = "NonProd Management Group ID"
  value       = azurerm_management_group.nonprod.id
}

output "management_group_structure" {
  description = "Complete management group hierarchy"
  value = {
    tenant_root = {
      id   = data.azurerm_management_group.tenant_root.id
      name = data.azurerm_management_group.tenant_root.display_name
    }
    platform = {
      id   = azurerm_management_group.platform.id
      name = azurerm_management_group.platform.display_name
      children = {
        identity = {
          id   = azurerm_management_group.identity.id
          name = azurerm_management_group.identity.display_name
        }
        connectivity = {
          id   = azurerm_management_group.connectivity.id
          name = azurerm_management_group.connectivity.display_name
        }
      }
    }
    landing_zones = {
      id   = azurerm_management_group.landing_zones.id
      name = azurerm_management_group.landing_zones.display_name
      children = {
        prod = {
          id   = azurerm_management_group.prod.id
          name = azurerm_management_group.prod.display_name
        }
        nonprod = {
          id   = azurerm_management_group.nonprod.id
          name = azurerm_management_group.nonprod.display_name
        }
      }
    }
  }
}
