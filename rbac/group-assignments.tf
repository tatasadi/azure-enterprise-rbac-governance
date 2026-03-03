# =============================================================================
# Platform Team Role Assignments (PIM-Eligible)
# =============================================================================
# These create PIM-eligible assignments via Terraform
# - Users must activate the role when needed (just-in-time access)
# - Eligibility duration: 1 year (automatically managed by Terraform)
# - Activation policies (max duration, approval, MFA): Configure in Azure Portal > PIM
# =============================================================================

# Platform Owner - Management Group Level (PIM-Eligible)
resource "azurerm_pim_eligible_role_assignment" "platform_owner" {
  scope              = data.azurerm_management_group.platform.id
  role_definition_id = data.azurerm_role_definition.owner.id
  principal_id       = azuread_group.platform_owner_eligible.object_id

  schedule {
    start_date_time = "2026-03-03T00:00:00Z"
    expiration {
      duration_hours = 8760  # 1 year eligibility (renewable)
    }
  }

  justification = "Platform Owner eligible assignment - requires activation for privileged operations"

  ticket {
    number = "RBAC-PLATFORM-001"
    system = "Terraform"
  }
}

# Platform Contributor - Management Group Level (PIM-Eligible)
resource "azurerm_pim_eligible_role_assignment" "platform_contributor" {
  scope              = data.azurerm_management_group.platform.id
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = azuread_group.platform_contributor_eligible.object_id

  schedule {
    start_date_time = "2026-03-03T00:00:00Z"
    expiration {
      duration_hours = 8760  # 1 year eligibility (renewable)
    }
  }

  justification = "Platform Contributor eligible assignment - requires activation for infrastructure changes"

  ticket {
    number = "RBAC-PLATFORM-002"
    system = "Terraform"
  }
}

# =============================================================================
# Network Team Role Assignments
# =============================================================================

resource "azurerm_role_assignment" "network_contributor" {
  scope                = data.azurerm_management_group.connectivity.id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_group.network_contributor.object_id
  description          = "Network team - Contributor access to Connectivity management group"
}

# =============================================================================
# Identity Team Role Assignments
# =============================================================================

resource "azurerm_role_assignment" "identity_contributor" {
  scope                = data.azurerm_management_group.identity.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.identity_contributor.object_id
  description          = "Identity team - Contributor access to Identity management group"
}

# =============================================================================
# Application Team Role Assignments (Management Group Level)
# =============================================================================

# Prod - Reader at Management Group level
resource "azurerm_role_assignment" "app_team_reader_prod" {
  scope                = data.azurerm_management_group.prod.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.app_team_reader_prod.object_id
  description          = "Application teams - Read-only access to Prod management group"
}

# NonProd - Reader at Management Group level
resource "azurerm_role_assignment" "app_team_reader_nonprod" {
  scope                = data.azurerm_management_group.nonprod.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.app_team_reader_nonprod.object_id
  description          = "Application teams - Read-only access to NonProd management group"
}

# Note: Contributor assignments for app teams will be done at Resource Group level
# This is intentional - app teams get Contributor only to their specific RGs, not the entire subscription

# =============================================================================
# Security & Audit Team Role Assignments
# =============================================================================

# Security Reader - Platform Management Group (read all security settings for Platform resources)
resource "azurerm_role_assignment" "security_reader_platform" {
  scope                = data.azurerm_management_group.platform.id
  role_definition_name = "Security Reader"
  principal_id         = azuread_group.security_reader.object_id
  description          = "Security team - Security Reader for Platform management group"
}

# Security Reader - Landing Zones Management Group (read all security settings for workloads)
resource "azurerm_role_assignment" "security_reader_landing_zones" {
  scope                = data.azurerm_management_group.landing_zones.id
  role_definition_name = "Security Reader"
  principal_id         = azuread_group.security_reader.object_id
  description          = "Security team - Security Reader for Landing Zones management group"
}

# Enhanced Security Reader for workloads (with Key Vault and policy access)
# NOTE: Custom roles with DataActions cannot be assigned at Management Group level
# Assigning at subscription level instead

resource "azurerm_role_assignment" "security_reader_workloads_prod" {
  scope                = "/subscriptions/${var.subscription_workload_prod}"
  role_definition_name = "CR-SecurityReader-Enterprise" # Custom role with DataActions
  principal_id         = azuread_group.security_reader.object_id
  description          = "Security team - Enhanced reader for Prod workload compliance and Key Vault audits"
}

resource "azurerm_role_assignment" "security_reader_workloads_nonprod" {
  scope                = "/subscriptions/${var.subscription_workload_nonprod}"
  role_definition_name = "CR-SecurityReader-Enterprise" # Custom role with DataActions
  principal_id         = azuread_group.security_reader.object_id
  description          = "Security team - Enhanced reader for NonProd workload compliance and Key Vault audits"
}

# Audit Reader - Platform Management Group (read-only for compliance)
resource "azurerm_role_assignment" "audit_reader_platform" {
  scope                = data.azurerm_management_group.platform.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.audit_reader.object_id
  description          = "Audit team - Reader access for Platform management group for compliance"
}

# Audit Reader - Landing Zones Management Group (read-only for compliance)
resource "azurerm_role_assignment" "audit_reader_landing_zones" {
  scope                = data.azurerm_management_group.landing_zones.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.audit_reader.object_id
  description          = "Audit team - Reader access for Landing Zones management group for compliance"
}

# =============================================================================
# Consultant Role Assignments (PIM-Eligible, Time-Limited)
# =============================================================================

# External Consultant - Contributor at LandingZones level (PIM-eligible, 90-day limit)
resource "azurerm_pim_eligible_role_assignment" "consultant_contributor" {
  scope              = data.azurerm_management_group.landing_zones.id
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = azuread_group.consultant_contributor_temp.object_id

  schedule {
    start_date_time = "2026-03-03T00:00:00Z"
    expiration {
      duration_hours = 2160  # 90 days (temporary engagement)
    }
  }

  justification = "External consultant temporary eligible assignment - 90-day engagement for Landing Zones workloads"

  ticket {
    number = "CONSULTANT-ENGAGEMENT-2026-Q1"
    system = "Terraform"
  }
}

# =============================================================================
# DevOps / CI/CD Role Assignments
# Note: These will use custom roles once created
# For now, using built-in Contributor (will be replaced with custom deployer role)
# =============================================================================

resource "azurerm_role_assignment" "devops_prod" {
  scope                = data.azurerm_management_group.prod.id
  role_definition_name = "CR-AppDeployer-ResourceGroup-Prod" # Custom role
  principal_id         = azuread_group.devops_deployer_prod.object_id
  description          = "DevOps pipelines - Deployer role for Prod (service principals only)"
}

resource "azurerm_role_assignment" "devops_nonprod" {
  scope                = data.azurerm_management_group.nonprod.id
  role_definition_name = "CR-AppDeployer-ResourceGroup-NonProd" # Custom role
  principal_id         = azuread_group.devops_deployer_nonprod.object_id
  description          = "DevOps pipelines - Deployer role for NonProd (service principals only)"
}
