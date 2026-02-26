data "azurerm_client_config" "current" {}

data "azurerm_management_group" "tenant_root" {
  name = data.azurerm_client_config.current.tenant_id
}

data "azurerm_management_group" "landing_zones" {
  display_name = "LandingZones"
}

# =============================================================================
# Policy Definition: Deny Owner Assignments at Subscription Scope
# =============================================================================

resource "azurerm_policy_definition" "deny_owner_at_subscription" {
  name         = "deny-owner-subscription-scope"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny Owner role assignment at subscription scope"
  description  = "Prevents direct Owner role assignments at subscription level. Use PIM at Management Group level instead."

  metadata = jsonencode({
    version  = "1.0.0"
    category = "RBAC Governance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Authorization/roleAssignments"
        },
        {
          field  = "Microsoft.Authorization/roleAssignments/roleDefinitionId"
          equals = "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
        },
        {
          value  = "[substring(field('Microsoft.Authorization/roleAssignments/scope'), 0, 15)]"
          equals = "/subscriptions/"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = [
        "Audit",
        "Deny",
        "Disabled"
      ]
      defaultValue = "Deny"
    }
  })

  management_group_id = data.azurerm_management_group.tenant_root.id
}

# =============================================================================
# Policy Definition: Audit Privileged Roles
# =============================================================================

resource "azurerm_policy_definition" "audit_privileged_roles" {
  name         = "audit-permanent-privileged-roles"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit permanent privileged role assignments"
  description  = "Audits permanent assignments of Owner, Contributor, and User Access Administrator roles."

  metadata = jsonencode({
    version  = "1.0.0"
    category = "RBAC Governance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          equals = "Microsoft.Authorization/roleAssignments"
        },
        {
          field = "Microsoft.Authorization/roleAssignments/roleDefinitionId"
          in    = "[parameters('privilegedRoleDefinitionIds')]"
        }
      ]
    }
    then = {
      effect = "Audit"
    }
  })

  parameters = jsonencode({
    privilegedRoleDefinitionIds = {
      type = "Array"
      metadata = {
        displayName = "Privileged Role Definition IDs"
        description = "List of role definition IDs considered privileged"
      }
      defaultValue = [
        "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635", # Owner
        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c", # Contributor
        "/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9"  # User Access Administrator
      ]
    }
  })

  management_group_id = data.azurerm_management_group.tenant_root.id
}

# =============================================================================
# Policy Definition: Require tags on resource groups
# =============================================================================

resource "azurerm_policy_definition" "require_rg_tags" {
  name         = "require-resourcegroup-tags"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require specific tags on resource groups"
  description  = "Enforces required tags on resource groups for governance and cost management."

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Tags"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          anyOf = [
            {
              field  = "tags['Environment']"
              exists = false
            },
            {
              field  = "tags['CostCenter']"
              exists = false
            },
            {
              field  = "tags['Owner']"
              exists = false
            }
          ]
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = [
        "Audit",
        "Deny",
        "Disabled"
      ]
      defaultValue = "Audit"
    }
  })

  management_group_id = data.azurerm_management_group.landing_zones.id
}

# =============================================================================
# Policy Assignments
# =============================================================================

# Assign: Deny Owner at Subscription - LandingZones scope
resource "azurerm_management_group_policy_assignment" "deny_owner_landingzones" {
  name                 = "deny-owner-sub-lz"
  policy_definition_id = azurerm_policy_definition.deny_owner_at_subscription.id
  management_group_id  = data.azurerm_management_group.landing_zones.id
  display_name         = "Deny Owner at Subscription (LandingZones)"
  description          = "Prevents Owner role assignments at subscription scope in LandingZones"

  parameters = jsonencode({
    effect = {
      value = var.deny_owner_effect
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

# Assign: Audit Privileged Roles - Tenant Root scope
resource "azurerm_management_group_policy_assignment" "audit_privileged_root" {
  name                 = "audit-priv-roles"
  policy_definition_id = azurerm_policy_definition.audit_privileged_roles.id
  management_group_id  = data.azurerm_management_group.tenant_root.id
  display_name         = "Audit Privileged Role Assignments (Tenant-wide)"
  description          = "Audits all permanent privileged role assignments across the tenant"

  identity {
    type = "SystemAssigned"
  }
}

# Assign: Require RG Tags - LandingZones scope
resource "azurerm_management_group_policy_assignment" "require_tags_landingzones" {
  name                 = "require-rg-tags-lz"
  policy_definition_id = azurerm_policy_definition.require_rg_tags.id
  management_group_id  = data.azurerm_management_group.landing_zones.id
  display_name         = "Require Resource Group Tags (LandingZones)"
  description          = "Enforces required tags on all resource groups in LandingZones"

  parameters = jsonencode({
    effect = {
      value = var.require_tags_effect
    }
  })

  identity {
    type = "SystemAssigned"
  }
}
