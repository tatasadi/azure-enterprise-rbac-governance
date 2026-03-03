# Azure RBAC Role Matrix

## Overview

This document provides a comprehensive matrix of all role assignments in the Azure enterprise governance model. All assignments follow the principle of group-based RBAC - **no direct user assignments**.

## Role Assignment Principles

1. **Zero direct user assignments** - All access via Entra ID security groups
2. **PIM for privileged roles** - Owner and high-risk Contributor assignments are PIM-eligible
3. **Scoped assignments** - Minimal scope necessary (MG > Subscription > RG)
4. **Custom roles** - Least-privilege roles for CI/CD and specialized functions
5. **Active assignments** - Only for non-privileged, scoped roles

---

## Complete Role Assignment Matrix

| Group Name | Azure Role | Scope | Assignment Type | Max Duration | Approval Required | Justification | MFA Required |
|------------|------------|-------|-----------------|--------------|-------------------|---------------|--------------|
| **Platform Team** | | | | | | | |
| AZ-ROL-Platform-Owner-Eligible | Owner | Platform MG | PIM Eligible | 2 hours | Yes | Yes | Yes |
| AZ-ROL-Platform-Contributor-Eligible | Contributor | Platform MG | PIM Eligible | 4 hours | No | Yes | Yes |
| **Application Teams** | | | | | | | |
| AZ-ROL-AppTeam-Contributor-Prod | Contributor | Resource Groups (Prod) | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-AppTeam-Contributor-NonProd | Contributor | Resource Groups (NonProd) | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-AppTeam-Reader-Prod | Reader | Prod MG | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-AppTeam-Reader-NonProd | Reader | NonProd MG | Active | N/A | N/A | N/A | N/A |
| **Security & Audit** | | | | | | | |
| AZ-ROL-Security-Reader | Security Reader | Platform MG | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-Security-Reader | Security Reader | LandingZones MG | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-Security-Reader | CR-SecurityReader-Enterprise | Workload-Prod Sub | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-Security-Reader | CR-SecurityReader-Enterprise | Workload-NonProd Sub | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-Audit-Reader | Reader | Platform MG | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-Audit-Reader | Reader | LandingZones MG | Active | N/A | N/A | N/A | N/A |
| **Network Team** | | | | | | | |
| AZ-ROL-Network-Contributor | Network Contributor | Connectivity MG | Active | N/A | N/A | N/A | N/A |
| **Identity Team** | | | | | | | |
| AZ-ROL-Identity-Contributor | Contributor | Identity MG | Active | N/A | N/A | N/A | N/A |
| **External Consultants** | | | | | | | |
| AZ-ROL-Consultant-Contributor-Temp | Contributor | LandingZones MG | PIM Eligible | 2 hours | Yes | Yes | Yes |
| **DevOps / CI/CD** | | | | | | | |
| AZ-ROL-DevOps-Deployer-Prod | CR-AppDeployer-ResourceGroup-Prod | Prod MG | Active | N/A | N/A | N/A | N/A |
| AZ-ROL-DevOps-Deployer-NonProd | CR-AppDeployer-ResourceGroup-NonProd | NonProd MG | Active | N/A | N/A | N/A | N/A |

---

## Detailed Group Descriptions

### Platform Team Groups

#### AZ-ROL-Platform-Owner-Eligible
- **Purpose:** Platform administrators who manage foundational Azure infrastructure
- **Members:** Senior platform engineers, cloud architects
- **Scope:** Platform Management Group (includes Identity and Connectivity MGs)
- **Assignment Type:** PIM Eligible
- **Activation Policy:**
  - Maximum duration: 2 hours
  - Approval required: Yes (Security Team + Platform Leads)
  - MFA required: Yes
  - Justification required: Yes
  - Ticket information: Optional
- **Eligibility Duration:** 180 days (auto-renewed by Terraform)
- **Use Cases:**
  - Creating/modifying management groups
  - Deploying core platform infrastructure (VNets, NSGs, Firewalls)
  - Managing RBAC assignments (via Terraform)
  - Emergency infrastructure changes

#### AZ-ROL-Platform-Contributor-Eligible
- **Purpose:** Platform engineers who deploy infrastructure without RBAC permissions
- **Members:** Platform engineers, DevOps team
- **Scope:** Platform Management Group
- **Assignment Type:** PIM Eligible
- **Activation Policy:**
  - Maximum duration: 4 hours
  - Approval required: No
  - MFA required: Yes
  - Justification required: Yes
  - Ticket information: Optional
- **Eligibility Duration:** 180 days (auto-renewed by Terraform)
- **Use Cases:**
  - Deploying platform resources
  - Troubleshooting infrastructure issues
  - Day-to-day operations (longer duration than Owner)

---

### Application Team Groups

#### AZ-ROL-AppTeam-Contributor-Prod
- **Purpose:** Application teams who deploy to Production
- **Members:** Application developers, DevOps engineers
- **Scope:** Specific Resource Groups in Prod subscription (assigned per-RG)
- **Assignment Type:** Active (no PIM activation required)
- **Rationale:**
  - Scoped to individual RGs (limited blast radius)
  - Prod access requires tight control
  - Resource Group-level assignment provides sufficient isolation
- **Use Cases:**
  - Deploying applications to assigned RGs
  - Managing app-specific resources (App Services, Storage, etc.)
  - Troubleshooting prod issues within their RG

#### AZ-ROL-AppTeam-Contributor-NonProd
- **Purpose:** Application teams who deploy to Non-Production environments
- **Members:** Application developers, QA engineers, DevOps
- **Scope:** Specific Resource Groups in NonProd subscription
- **Assignment Type:** Active
- **Use Cases:**
  - Deploying to Dev/Test/Staging environments
  - Experimentation and testing
  - CI/CD pipeline testing

#### AZ-ROL-AppTeam-Reader-Prod
- **Purpose:** Read-only access to Prod for visibility and troubleshooting
- **Members:** All application team members, junior engineers
- **Scope:** Prod Management Group
- **Assignment Type:** Active
- **Use Cases:**
  - Viewing prod resource configurations
  - Monitoring and observability
  - Investigating issues without modification permissions

#### AZ-ROL-AppTeam-Reader-NonProd
- **Purpose:** Read-only access to NonProd for visibility
- **Members:** All application team members
- **Scope:** NonProd Management Group
- **Assignment Type:** Active

---

### Security & Audit Team Groups

#### AZ-ROL-Security-Reader
- **Purpose:** Security team members who audit security posture
- **Members:** Security engineers, security analysts
- **Scope:** Multiple assignments:
  - Security Reader @ Platform MG
  - Security Reader @ LandingZones MG
  - CR-SecurityReader-Enterprise @ Workload-Prod Subscription
  - CR-SecurityReader-Enterprise @ Workload-NonProd Subscription
- **Assignment Type:** Active
- **Special Permissions (Custom Role):**
  - Read all resource properties
  - Read PIM settings and role assignments
  - Read Azure Policy compliance
  - **Read Key Vault secrets** (DataAction - for security audits)
  - Read security center and security insights
  - Query Log Analytics workspaces
- **Use Cases:**
  - Security compliance auditing
  - Vulnerability assessments
  - PIM activation reviews
  - Policy compliance validation
  - Key Vault secret auditing (for compliance, not usage)

#### AZ-ROL-Audit-Reader
- **Purpose:** Audit/compliance team members
- **Members:** Compliance officers, auditors
- **Scope:**
  - Reader @ Platform MG
  - Reader @ LandingZones MG
- **Assignment Type:** Active
- **Use Cases:**
  - Compliance reporting
  - Cost analysis
  - Resource inventory audits
  - Access reviews

---

### Network Team Group

#### AZ-ROL-Network-Contributor
- **Purpose:** Network administrators who manage connectivity
- **Members:** Network engineers
- **Scope:** Connectivity Management Group
- **Assignment Type:** Active (scoped, so PIM not required)
- **Role:** Network Contributor (built-in Azure role)
- **Permissions:**
  - Create/modify virtual networks, subnets
  - Manage NSGs, route tables
  - Configure VPN gateways, ExpressRoute
  - Manage Azure Firewall, load balancers
  - Cannot assign roles or delete resource groups
- **Use Cases:**
  - Hub-spoke network architecture management
  - Firewall rule configuration
  - VPN/ExpressRoute management
  - Network troubleshooting

---

### Identity Team Group

#### AZ-ROL-Identity-Contributor
- **Purpose:** Identity team members who manage identity infrastructure
- **Members:** Identity engineers, Entra ID admins
- **Scope:** Identity Management Group
- **Assignment Type:** Active (scoped)
- **Role:** Contributor (built-in)
- **Use Cases:**
  - Deploying identity-related resources
  - Managing AD Domain Controllers (if IaaS)
  - Managing Entra ID Domain Services
  - Identity infrastructure troubleshooting

---

### External Consultant Groups

#### AZ-ROL-Consultant-Contributor-Temp
- **Purpose:** Temporary access for external consultants/vendors
- **Members:** External consultants (short-term engagements)
- **Scope:** LandingZones Management Group
- **Assignment Type:** PIM Eligible (time-limited)
- **Activation Policy:**
  - Maximum duration: 2 hours
  - Approval required: Yes (Security Team only)
  - MFA required: Yes
  - Justification required: Yes
  - Ticket information: Recommended (include engagement ticket)
- **Eligibility Duration:** 90 days (consultant engagement period)
- **Rationale:**
  - Short-term access for project-based work
  - Automatically expires after 90 days
  - Requires approval for every activation
  - Scoped to workloads only (not Platform)
- **Use Cases:**
  - Third-party consulting engagements
  - Migration projects
  - Temporary augmentation of internal teams

---

### DevOps / CI/CD Groups

#### AZ-ROL-DevOps-Deployer-Prod
- **Purpose:** Service principals for CI/CD pipelines (Prod)
- **Members:** Azure DevOps service principals, GitHub Actions identities
- **Scope:** Prod Management Group
- **Assignment Type:** Active
- **Role:** CR-AppDeployer-ResourceGroup-Prod (Custom Role)
- **Permissions:**
  - Deploy ARM templates, Terraform
  - Create/modify app resources (VMs, Storage, SQL, App Services, etc.)
  - Read/write Key Vault secrets (for app configuration)
  - Manage monitoring and logging
  - **Cannot:**
    - Assign roles
    - Delete resource groups
    - Modify virtual networks (read-only)
    - Modify Key Vault access policies
- **Use Cases:**
  - Azure DevOps release pipelines
  - GitHub Actions workflows
  - Terraform Apply operations
  - Automated deployments

#### AZ-ROL-DevOps-Deployer-NonProd
- **Purpose:** Service principals for CI/CD pipelines (NonProd)
- **Members:** Same as Prod
- **Scope:** NonProd Management Group
- **Assignment Type:** Active
- **Role:** CR-AppDeployer-ResourceGroup-NonProd (Custom Role)
- **Permissions:** Same as Prod variant

---

## Custom Roles Detail

### CR-AppDeployer-ResourceGroup-Prod

**Assignable Scopes:** Prod Management Group

**Actions Allowed:**
```
✅ Microsoft.Resources/deployments/*
✅ Microsoft.Resources/subscriptions/resourceGroups/read
✅ Microsoft.Resources/subscriptions/resourceGroups/write
✅ Microsoft.Web/sites/*
✅ Microsoft.Web/serverfarms/*
✅ Microsoft.Storage/storageAccounts/*
✅ Microsoft.Sql/servers/*
✅ Microsoft.KeyVault/vaults/read
✅ Microsoft.KeyVault/vaults/secrets/read
✅ Microsoft.KeyVault/vaults/secrets/write
✅ Microsoft.Insights/*
✅ Microsoft.Network/virtualNetworks/read
✅ Microsoft.Network/virtualNetworks/subnets/read
✅ Microsoft.Network/virtualNetworks/subnets/join/action
✅ Microsoft.Compute/virtualMachines/read
✅ Microsoft.Compute/virtualMachines/write
✅ Microsoft.Compute/virtualMachines/delete
✅ Microsoft.ContainerRegistry/registries/*
✅ Microsoft.DocumentDB/databaseAccounts/*
✅ Microsoft.Cache/redis/*
```

**Actions Denied (NotActions):**
```
❌ Microsoft.Authorization/*/write (cannot assign roles)
❌ Microsoft.Authorization/*/delete (cannot delete role assignments)
❌ Microsoft.Resources/subscriptions/resourceGroups/delete (cannot delete RGs)
❌ Microsoft.KeyVault/vaults/delete (cannot delete Key Vaults)
❌ Microsoft.KeyVault/vaults/accessPolicies/* (cannot modify access policies)
❌ Microsoft.Network/virtualNetworks/delete (cannot delete VNets)
❌ Microsoft.Network/virtualNetworks/write (cannot modify VNets)
```

**Rationale:** This role allows CI/CD pipelines to deploy applications without the ability to:
- Escalate privileges (no role assignments)
- Delete critical infrastructure (RGs, VNets, Key Vaults)
- Modify network topology
- Change Key Vault access policies

---

### CR-AppDeployer-ResourceGroup-NonProd

**Assignable Scopes:** NonProd Management Group

**Permissions:** Identical to Prod variant (consistency across environments)

---

### CR-SecurityReader-Enterprise

**Assignable Scopes:** LandingZones Management Group

**Actions Allowed:**
```
✅ */read (read all resources)
✅ Microsoft.Authorization/*/read (read role assignments)
✅ Microsoft.PolicyInsights/*/read (read policy compliance)
✅ Microsoft.Security/*/read (read security settings)
✅ Microsoft.SecurityInsights/*/read (read Sentinel data)
✅ Microsoft.OperationalInsights/workspaces/query/read (query logs)
✅ Microsoft.Insights/*/read (read monitoring data)
```

**DataActions Allowed:**
```
✅ Microsoft.KeyVault/vaults/secrets/getSecret/action (read KV secrets)
✅ Microsoft.KeyVault/vaults/certificates/read (read certificates)
```

**Rationale:** Security teams need:
- Full read access to audit resources
- Ability to read Key Vault secrets for compliance validation
- Access to policy compliance and security insights
- Cannot modify anything (read-only)

**Note:** Custom roles with DataActions cannot be assigned at Management Group level, so this role is assigned at the subscription level.

---

## PIM Eligibility Duration Summary

| Group | Eligibility Duration | Managed By | Renewal |
|-------|---------------------|------------|---------|
| AZ-ROL-Platform-Owner-Eligible | 180 days | Terraform | Automatic |
| AZ-ROL-Platform-Contributor-Eligible | 180 days | Terraform | Automatic |
| AZ-ROL-Consultant-Contributor-Temp | 90 days | Terraform | Manual (engagement end) |

**Note:** Terraform manages eligibility duration. The `azurerm_pim_eligible_role_assignment` resource automatically renews eligible assignments on each `terraform apply`.

---

## Assignment Scope Hierarchy

```
Tenant Root
├── Platform MG
│   ├── PIM: Platform-Owner-Eligible (Owner)
│   ├── PIM: Platform-Contributor-Eligible (Contributor)
│   ├── Active: Security-Reader (Security Reader)
│   ├── Active: Audit-Reader (Reader)
│   │
│   ├── Identity MG
│   │   └── Active: Identity-Contributor (Contributor)
│   │
│   └── Connectivity MG
│       └── Active: Network-Contributor (Network Contributor)
│
└── LandingZones MG
    ├── PIM: Consultant-Contributor-Temp (Contributor)
    ├── Active: Security-Reader (Security Reader)
    ├── Active: Audit-Reader (Reader)
    │
    ├── Prod MG
    │   ├── Active: AppTeam-Reader-Prod (Reader)
    │   ├── Active: DevOps-Deployer-Prod (Custom)
    │   └── Resource Groups
    │       └── Active: AppTeam-Contributor-Prod (Contributor)
    │
    └── NonProd MG
        ├── Active: AppTeam-Reader-NonProd (Reader)
        ├── Active: DevOps-Deployer-NonProd (Custom)
        └── Resource Groups
            └── Active: AppTeam-Contributor-NonProd (Contributor)
```

---

## Break-Glass Account

**NOT managed by this RBAC model** - configured separately for emergency access.

| Account | Role | Scope | Assignment Type | Notes |
|---------|------|-------|-----------------|-------|
| breakglass@domain.com | Owner | Tenant Root MG | Permanent | ⚠️ Emergency only, stored offline, alerts on usage |

---

## Role Assignment Change Process

All role assignment changes **must** go through Terraform and the CI/CD pipeline:

1. Developer modifies Terraform code (add/remove groups or assignments)
2. Create Pull Request
3. Pipeline runs `terraform plan` → highlights RBAC changes
4. **Approval gate** - Security Team + Platform Team review
5. Pipeline runs `terraform apply` after approval
6. Changes logged in Git and Azure Activity Log

**No manual role assignments** in the Azure Portal (except emergency break-glass scenarios).

---

## Group Membership Management

| Group | Membership Managed By | Approval Required |
|-------|----------------------|-------------------|
| Platform-Owner-Eligible | Platform Lead | Yes (Security Team) |
| Platform-Contributor-Eligible | Platform Lead | Yes |
| AppTeam-* groups | Application Team Leads | Yes (Platform Team) |
| Security-Reader | CISO | Yes (CISO) |
| Audit-Reader | Compliance Manager | Yes (CISO) |
| Network-Contributor | Network Manager | Yes (Platform Team) |
| Identity-Contributor | Identity Manager | Yes (Platform Team) |
| Consultant-Contributor-Temp | Engagement Manager | Yes (Security + Procurement) |
| DevOps-Deployer-* | Platform Lead | Yes (Service Principals only) |

---

## Quarterly Access Review Checklist

- [ ] Review all Entra ID group memberships
- [ ] Verify all PIM eligible assignments are still required
- [ ] Check for any manual role assignments (should be none)
- [ ] Review consultant access (remove expired engagements)
- [ ] Validate service principal assignments
- [ ] Test break-glass account access
- [ ] Review PIM activation logs for anomalies
- [ ] Update role matrix with any new groups/roles

---

## References

- [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [PIM role settings](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-resource-roles-configure-role-settings)
- [Custom roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles)

---

**Last Updated:** 2026-03-03
**Version:** 1.0
**Maintained By:** Platform Team
