# Data sources for management groups (created in management-groups module)
data "azurerm_client_config" "current" {}

# Data sources for built-in role definitions (needed for PIM assignments)
data "azurerm_role_definition" "owner" {
  name  = "Owner"
  scope = data.azurerm_management_group.platform.id
}

data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = data.azurerm_management_group.platform.id
}

data "azurerm_management_group" "platform" {
  display_name = "Platform"
}

data "azurerm_management_group" "identity" {
  display_name = "Identity"
}

data "azurerm_management_group" "connectivity" {
  display_name = "Connectivity"
}

data "azurerm_management_group" "landing_zones" {
  display_name = "LandingZones"
}

data "azurerm_management_group" "prod" {
  display_name = "Prod"
}

data "azurerm_management_group" "nonprod" {
  display_name = "NonProd"
}
