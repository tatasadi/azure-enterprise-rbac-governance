output "entra_groups" {
  description = "All Entra ID security groups created"
  value = {
    platform = {
      owner_eligible       = azuread_group.platform_owner_eligible.id
      contributor_eligible = azuread_group.platform_contributor_eligible.id
    }
    app_teams = {
      contributor_prod    = azuread_group.app_team_contributor_prod.id
      contributor_nonprod = azuread_group.app_team_contributor_nonprod.id
      reader_prod         = azuread_group.app_team_reader_prod.id
      reader_nonprod      = azuread_group.app_team_reader_nonprod.id
    }
    security_audit = {
      security_reader = azuread_group.security_reader.id
      audit_reader    = azuread_group.audit_reader.id
    }
    network = {
      contributor = azuread_group.network_contributor.id
    }
    identity = {
      contributor = azuread_group.identity_contributor.id
    }
    consultants = {
      contributor_temp = azuread_group.consultant_contributor_temp.id
    }
    devops = {
      deployer_prod    = azuread_group.devops_deployer_prod.id
      deployer_nonprod = azuread_group.devops_deployer_nonprod.id
    }
  }
}

output "pim_eligible_assignments" {
  description = "PIM-eligible role assignments managed by Terraform"
  value = {
    platform_owner = {
      group             = azuread_group.platform_owner_eligible.display_name
      role              = "Owner"
      scope             = "Platform Management Group"
      eligibility_type  = "PIM-Eligible"
      duration          = "1 year"
      activation_policy = "Configure activation settings (max duration, approval, MFA) in Azure Portal PIM settings"
    }
    platform_contributor = {
      group             = azuread_group.platform_contributor_eligible.display_name
      role              = "Contributor"
      scope             = "Platform Management Group"
      eligibility_type  = "PIM-Eligible"
      duration          = "1 year"
      activation_policy = "Configure activation settings (max duration, approval, MFA) in Azure Portal PIM settings"
    }
    consultant_contributor = {
      group             = azuread_group.consultant_contributor_temp.display_name
      role              = "Contributor"
      scope             = "Landing Zones Management Group"
      eligibility_type  = "PIM-Eligible (Time-Limited)"
      duration          = "90 days"
      activation_policy = "Configure activation settings (max duration, approval, MFA) in Azure Portal PIM settings"
    }
  }
}

output "role_assignments_summary" {
  description = "Summary of all role assignments (PIM-eligible and active)"
  value = {
    pim_eligible_count = 3
    active_count       = 11
    note               = "PIM-eligible assignments managed by Terraform. Activation policies (approval, MFA, max duration) configured in Azure Portal."
  }
}
