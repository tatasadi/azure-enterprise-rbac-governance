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

output "group_names_for_pim_configuration" {
  description = "Groups that should be configured as PIM-eligible in Azure Portal"
  value = [
    azuread_group.platform_owner_eligible.display_name,
    azuread_group.platform_contributor_eligible.display_name,
    azuread_group.consultant_contributor_temp.display_name,
  ]
}

output "role_assignments_summary" {
  description = "Summary of role assignments created"
  value = {
    platform_owner = {
      group = azuread_group.platform_owner_eligible.display_name
      role  = "Owner"
      scope = "Platform Management Group"
      note  = "Configure as PIM-eligible in Azure Portal"
    }
    security_reader = {
      group = azuread_group.security_reader.display_name
      role  = "Security Reader"
      scope = "Tenant Root"
      note  = "Active assignment"
    }
    audit_reader = {
      group = azuread_group.audit_reader.display_name
      role  = "Reader"
      scope = "Tenant Root"
      note  = "Active assignment"
    }
  }
}
