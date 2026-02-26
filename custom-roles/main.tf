data "azurerm_client_config" "current" {}

data "azurerm_management_group" "prod" {
  display_name = var.management_group_prod
}

data "azurerm_management_group" "nonprod" {
  display_name = var.management_group_nonprod
}

data "azurerm_management_group" "landing_zones" {
  display_name = var.management_group_landing_zones
}

# App Deployer Custom Role - Prod
resource "azurerm_role_definition" "app_deployer_prod" {
  name        = "CR-AppDeployer-ResourceGroup-Prod"
  scope       = data.azurerm_management_group.prod.id
  description = "Can deploy and manage application resources but cannot assign roles or delete resource groups. Designed for CI/CD pipelines."

  permissions {
    actions = [
      "Microsoft.Resources/deployments/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Web/sites/*",
      "Microsoft.Web/serverfarms/*",
      "Microsoft.Web/certificates/*",
      "Microsoft.Storage/storageAccounts/*",
      "Microsoft.Sql/servers/*",
      "Microsoft.Sql/managedInstances/read",
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/secrets/read",
      "Microsoft.KeyVault/vaults/secrets/write",
      "Microsoft.Insights/*",
      "Microsoft.OperationalInsights/*",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/loadBalancers/*",
      "Microsoft.ContainerRegistry/registries/*",
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Compute/disks/*",
      "Microsoft.DocumentDB/databaseAccounts/*",
      "Microsoft.Cache/redis/*",
    ]

    not_actions = [
      "Microsoft.Authorization/*/write",
      "Microsoft.Authorization/*/delete",
      "Microsoft.Resources/subscriptions/resourceGroups/delete",
      "Microsoft.KeyVault/vaults/delete",
      "Microsoft.KeyVault/vaults/accessPolicies/*",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/write",
    ]

    data_actions     = []
    not_data_actions = []
  }

  assignable_scopes = [
    data.azurerm_management_group.prod.id,
  ]
}

# App Deployer Custom Role - NonProd
resource "azurerm_role_definition" "app_deployer_nonprod" {
  name        = "CR-AppDeployer-ResourceGroup-NonProd"
  scope       = data.azurerm_management_group.nonprod.id
  description = "Can deploy and manage application resources but cannot assign roles or delete resource groups. Designed for CI/CD pipelines."

  permissions {
    actions = [
      "Microsoft.Resources/deployments/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Web/sites/*",
      "Microsoft.Web/serverfarms/*",
      "Microsoft.Web/certificates/*",
      "Microsoft.Storage/storageAccounts/*",
      "Microsoft.Sql/servers/*",
      "Microsoft.Sql/managedInstances/read",
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/secrets/read",
      "Microsoft.KeyVault/vaults/secrets/write",
      "Microsoft.Insights/*",
      "Microsoft.OperationalInsights/*",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/loadBalancers/*",
      "Microsoft.ContainerRegistry/registries/*",
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Compute/disks/*",
      "Microsoft.DocumentDB/databaseAccounts/*",
      "Microsoft.Cache/redis/*",
    ]

    not_actions = [
      "Microsoft.Authorization/*/write",
      "Microsoft.Authorization/*/delete",
      "Microsoft.Resources/subscriptions/resourceGroups/delete",
      "Microsoft.KeyVault/vaults/delete",
      "Microsoft.KeyVault/vaults/accessPolicies/*",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/write",
    ]

    data_actions     = []
    not_data_actions = []
  }

  assignable_scopes = [
    data.azurerm_management_group.nonprod.id,
  ]
}

# Security Reader Custom Role - LandingZones level (covers both Prod and NonProd)
resource "azurerm_role_definition" "security_reader" {
  name        = "CR-SecurityReader-Enterprise"
  scope       = data.azurerm_management_group.landing_zones.id
  description = "Read-only access to security-related resources including PIM, Policy compliance, role assignments, and security settings."

  permissions {
    actions = [
      "*/read",
      "Microsoft.Authorization/*/read",
      "Microsoft.PolicyInsights/*/read",
      "Microsoft.Security/*/read",
      "Microsoft.SecurityInsights/*/read",
      "Microsoft.OperationalInsights/workspaces/query/read",
      "Microsoft.Insights/*/read",
      "Microsoft.Management/managementGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/deployments/read",
      "Microsoft.Support/*/read",
    ]

    not_actions = []

    data_actions = [
      "Microsoft.KeyVault/vaults/secrets/getSecret/action",
      "Microsoft.KeyVault/vaults/certificates/read",
    ]

    not_data_actions = []
  }

  assignable_scopes = [
    data.azurerm_management_group.landing_zones.id,
  ]
}
