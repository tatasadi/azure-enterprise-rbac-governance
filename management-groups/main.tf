# Get the Tenant Root Management Group
data "azurerm_client_config" "current" {}

# Import existing Platform Management Group
resource "azurerm_management_group" "platform" {
  display_name = "Platform"
  # Omitting parent_management_group_id defaults to Tenant Root

  lifecycle {
    prevent_destroy = true
  }
}

# Identity Management Group (under Platform)
resource "azurerm_management_group" "identity" {
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id

  lifecycle {
    prevent_destroy = true
  }
}

# Connectivity Management Group (under Platform)
resource "azurerm_management_group" "connectivity" {
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id

  lifecycle {
    prevent_destroy = true
  }
}

# Landing Zones Management Group
resource "azurerm_management_group" "landing_zones" {
  display_name = "LandingZones"
  # Omitting parent_management_group_id defaults to Tenant Root

  lifecycle {
    prevent_destroy = true
  }
}

# Prod Management Group (under LandingZones)
resource "azurerm_management_group" "prod" {
  display_name               = "Prod"
  parent_management_group_id = azurerm_management_group.landing_zones.id

  lifecycle {
    prevent_destroy = true
  }
}

# NonProd Management Group (under LandingZones)
resource "azurerm_management_group" "nonprod" {
  display_name               = "NonProd"
  parent_management_group_id = azurerm_management_group.landing_zones.id

  lifecycle {
    prevent_destroy = true
  }
}

# Subscription Associations
resource "azurerm_management_group_subscription_association" "platform_connectivity" {
  management_group_id = azurerm_management_group.connectivity.id
  subscription_id     = "/subscriptions/${var.subscription_platform_connectivity}"
}

resource "azurerm_management_group_subscription_association" "platform_identity" {
  management_group_id = azurerm_management_group.identity.id
  subscription_id     = "/subscriptions/${var.subscription_platform_identity}"
}

resource "azurerm_management_group_subscription_association" "workload_prod" {
  management_group_id = azurerm_management_group.prod.id
  subscription_id     = "/subscriptions/${var.subscription_workload_prod}"
}

resource "azurerm_management_group_subscription_association" "workload_nonprod" {
  management_group_id = azurerm_management_group.nonprod.id
  subscription_id     = "/subscriptions/${var.subscription_workload_nonprod}"
}
