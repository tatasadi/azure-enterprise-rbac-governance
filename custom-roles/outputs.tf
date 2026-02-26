output "custom_role_ids" {
  description = "Custom role definition IDs"
  value = {
    app_deployer_prod    = azurerm_role_definition.app_deployer_prod.role_definition_id
    app_deployer_nonprod = azurerm_role_definition.app_deployer_nonprod.role_definition_id
    security_reader      = azurerm_role_definition.security_reader.role_definition_id
  }
}

output "custom_role_names" {
  description = "Custom role definition names"
  value = {
    app_deployer_prod    = azurerm_role_definition.app_deployer_prod.name
    app_deployer_nonprod = azurerm_role_definition.app_deployer_nonprod.name
    security_reader      = azurerm_role_definition.security_reader.name
  }
}
