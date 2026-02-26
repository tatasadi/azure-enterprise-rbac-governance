# =============================================================================
# Platform Team Groups (PIM-Eligible)
# =============================================================================

resource "azuread_group" "platform_owner_eligible" {
  display_name     = "AZ-ROL-Platform-Owner-Eligible"
  description      = "Platform team - Owner role via PIM (eligible only, 2h activation, approval required)"
  security_enabled = true

  owners = var.group_owners
}

resource "azuread_group" "platform_contributor_eligible" {
  display_name     = "AZ-ROL-Platform-Contributor-Eligible"
  description      = "Platform team - Contributor role via PIM (eligible only, 2h activation)"
  security_enabled = true

  owners = var.group_owners
}

# =============================================================================
# Application Team Groups (Active Assignments)
# =============================================================================

resource "azuread_group" "app_team_contributor_prod" {
  display_name     = "AZ-ROL-AppTeam-Contributor-Prod"
  description      = "Application teams - Contributor access to Prod resource groups (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

resource "azuread_group" "app_team_contributor_nonprod" {
  display_name     = "AZ-ROL-AppTeam-Contributor-NonProd"
  description      = "Application teams - Contributor access to NonProd resource groups (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

resource "azuread_group" "app_team_reader_prod" {
  display_name     = "AZ-ROL-AppTeam-Reader-Prod"
  description      = "Application teams - Read-only access to Prod (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

resource "azuread_group" "app_team_reader_nonprod" {
  display_name     = "AZ-ROL-AppTeam-Reader-NonProd"
  description      = "Application teams - Read-only access to NonProd (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

# =============================================================================
# Security & Audit Groups
# =============================================================================

resource "azuread_group" "security_reader" {
  display_name     = "AZ-ROL-Security-Reader"
  description      = "Security team - Custom Security Reader role across all scopes (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

resource "azuread_group" "audit_reader" {
  display_name     = "AZ-ROL-Audit-Reader"
  description      = "Audit team - Reader access to all subscriptions for compliance (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

# =============================================================================
# Network Team Groups
# =============================================================================

resource "azuread_group" "network_contributor" {
  display_name     = "AZ-ROL-Network-Contributor"
  description      = "Network team - Contributor access to Connectivity subscription (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

# =============================================================================
# Identity Team Groups
# =============================================================================

resource "azuread_group" "identity_contributor" {
  display_name     = "AZ-ROL-Identity-Contributor"
  description      = "Identity team - Contributor access to Identity subscription (active assignment)"
  security_enabled = true

  owners = var.group_owners
}

# =============================================================================
# External Consultants (PIM-Eligible, Time-Limited)
# =============================================================================

resource "azuread_group" "consultant_contributor_temp" {
  display_name     = "AZ-ROL-Consultant-Contributor-Temp"
  description      = "External consultants - Temporary Contributor via PIM (2h activation, approval required, 90-day eligibility)"
  security_enabled = true

  owners = var.group_owners
}

# =============================================================================
# DevOps / CI/CD Groups
# =============================================================================

resource "azuread_group" "devops_deployer_prod" {
  display_name     = "AZ-ROL-DevOps-Deployer-Prod"
  description      = "DevOps pipelines - Custom deployer role for Prod (service principals only)"
  security_enabled = true

  owners = var.group_owners
}

resource "azuread_group" "devops_deployer_nonprod" {
  display_name     = "AZ-ROL-DevOps-Deployer-NonProd"
  description      = "DevOps pipelines - Custom deployer role for NonProd (service principals only)"
  security_enabled = true

  owners = var.group_owners
}
