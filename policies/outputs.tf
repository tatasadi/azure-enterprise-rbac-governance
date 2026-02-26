output "policy_definitions" {
  description = "Custom policy definitions created"
  value = {
    deny_owner_at_subscription = {
      id   = azurerm_policy_definition.deny_owner_at_subscription.id
      name = azurerm_policy_definition.deny_owner_at_subscription.display_name
    }
    audit_privileged_roles = {
      id   = azurerm_policy_definition.audit_privileged_roles.id
      name = azurerm_policy_definition.audit_privileged_roles.display_name
    }
    require_rg_tags = {
      id   = azurerm_policy_definition.require_rg_tags.id
      name = azurerm_policy_definition.require_rg_tags.display_name
    }
  }
}

output "policy_assignments" {
  description = "Policy assignments created"
  value = {
    deny_owner_landingzones = {
      id    = azurerm_management_group_policy_assignment.deny_owner_landingzones.id
      scope = data.azurerm_management_group.landing_zones.id
    }
    audit_privileged_root = {
      id    = azurerm_management_group_policy_assignment.audit_privileged_root.id
      scope = data.azurerm_management_group.tenant_root.id
    }
    require_tags_landingzones = {
      id    = azurerm_management_group_policy_assignment.require_tags_landingzones.id
      scope = data.azurerm_management_group.landing_zones.id
    }
  }
}
