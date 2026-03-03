# Azure Enterprise RBAC & PIM Governance - Architecture Diagram

## System Architecture Overview

This document provides visual and textual representations of the Azure RBAC and PIM governance architecture.

## Management Group Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                      Tenant Root Group                       │
│                 (Highest level in hierarchy)                 │
└──────────────────┬──────────────────┬───────────────────────┘
                   │                  │
         ┌─────────▼─────────┐   ┌───▼─────────────────┐
         │     Platform      │   │   LandingZones      │
         │  Management Group │   │ Management Group    │
         └─────────┬─────────┘   └───┬─────────────────┘
                   │                 │
         ┌─────────┴─────────┐      └────┬────────────┐
         │                   │           │            │
    ┌────▼────┐       ┌──────▼───┐  ┌───▼───┐   ┌────▼─────┐
    │Identity │       │Connectivity│ │ Prod  │   │ NonProd  │
    │   MG    │       │    MG      │ │  MG   │   │   MG     │
    └────┬────┘       └──────┬─────┘ └───┬───┘   └────┬─────┘
         │                   │           │            │
         │                   │           │            │
    ┌────▼────────┐    ┌─────▼───────┐  │            │
    │ Platform-   │    │ Platform-   │  │            │
    │ Identity    │    │ Connectivity│  │            │
    │Subscription │    │Subscription │  │            │
    └─────────────┘    └─────────────┘  │            │
                                        │            │
                                   ┌────▼────────┐  │
                                   │ Workload-   │  │
                                   │    Prod     │  │
                                   │Subscription │  │
                                   └─────────────┘  │
                                                    │
                                              ┌─────▼──────┐
                                              │ Workload-  │
                                              │  NonProd   │
                                              │Subscription│
                                              └────────────┘
```

## RBAC Model - Group-Based Access

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Entra ID Security Groups                          │
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  Platform Team   │  │ Application Team │  │  Security Team   │  │
│  │                  │  │                  │  │                  │  │
│  │ Platform-Owner-  │  │ AppTeam-Contrib- │  │ Security-Reader  │  │
│  │   Eligible       │  │  Prod/NonProd    │  │                  │  │
│  │                  │  │                  │  │                  │  │
│  │ Platform-Contrib-│  │ AppTeam-Reader-  │  │ Audit-Reader     │  │
│  │   Eligible       │  │  Prod/NonProd    │  │                  │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│           │                     │                     │             │
└───────────┼─────────────────────┼─────────────────────┼─────────────┘
            │                     │                     │
            │ PIM Eligible        │ Active Assignment   │ Active
            │ Assignment          │                     │ Assignment
            │                     │                     │
            ▼                     ▼                     ▼
┌───────────────────────────────────────────────────────────────────────┐
│                   Azure Role Assignments                              │
│                                                                       │
│  ┌────────────────────┐  ┌─────────────────┐  ┌──────────────────┐  │
│  │  Owner/Contributor │  │   Contributor   │  │ Security Reader  │  │
│  │        Role        │  │      Role       │  │      Role        │  │
│  │  @ Platform MG     │  │  @ Prod/NonProd │  │ @ Platform/LZ    │  │
│  │                    │  │       MG        │  │       MG         │  │
│  │  (PIM - requires   │  │                 │  │                  │  │
│  │   activation)      │  │  (Active)       │  │   (Active)       │  │
│  └────────────────────┘  └─────────────────┘  └──────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

## PIM Activation Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                     User Requests Access                             │
│                                                                      │
│  User navigates to PIM → My Roles → Azure Resources                 │
│                                                                      │
│  User clicks "Activate" on eligible role                            │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                             │
│              │  PIM Policy Checks:    │                             │
│              │  • User is member of   │                             │
│              │    eligible group?     │                             │
│              │  • Eligibility not     │                             │
│              │    expired?            │                             │
│              └────────┬───────────────┘                             │
│                       │                                              │
│                       ▼                                              │
│              ┌────────────────────────┐                             │
│              │  User Provides:        │                             │
│              │  • Duration (max 2-4h) │                             │
│              │  • Justification       │                             │
│              │  • (Optional) Ticket # │                             │
│              │  • MFA Challenge       │                             │
│              └────────┬───────────────┘                             │
│                       │                                              │
│          ┌────────────▼────────────┐                                │
│          │ Approval Required?      │                                │
│          └──┬──────────────────┬───┘                                │
│             │ Yes              │ No                                 │
│             ▼                  ▼                                     │
│  ┌──────────────────┐   ┌─────────────────┐                        │
│  │  Send to         │   │  Auto-Approve   │                        │
│  │  Approvers       │   │  Role Active    │                        │
│  │  (Security Team) │   │  for Duration   │                        │
│  └────────┬─────────┘   └─────────────────┘                        │
│           │                                                          │
│           ▼                                                          │
│  ┌──────────────────┐                                               │
│  │  Approver        │                                               │
│  │  Reviews &       │                                               │
│  │  Approves/Denies │                                               │
│  └────────┬─────────┘                                               │
│           │                                                          │
│           ▼                                                          │
│  ┌──────────────────┐                                               │
│  │  If Approved:    │                                               │
│  │  Role Active     │                                               │
│  │  for Duration    │                                               │
│  └──────────────────┘                                               │
│                                                                      │
│  After expiration (2-4h), role automatically deactivates            │
└──────────────────────────────────────────────────────────────────────┘
```

## Azure Policy Enforcement Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Azure Policies                                 │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Policy 1: Deny Owner Assignments at Subscription Scope   │    │
│  │                                                            │    │
│  │  Effect: Deny                                             │    │
│  │  Scope: LandingZones Management Group                     │    │
│  │  Purpose: Force use of PIM at Management Group level      │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Policy 2: Audit Permanent Privileged Roles               │    │
│  │                                                            │    │
│  │  Effect: Audit                                            │    │
│  │  Scope: Platform & LandingZones MGs                       │    │
│  │  Monitors: Owner, Contributor, User Access Admin          │    │
│  │  Purpose: Detect permanent privileged assignments         │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Policy 3: Require Resource Group Tags                    │    │
│  │                                                            │    │
│  │  Effect: Audit (can be set to Deny)                      │    │
│  │  Scope: LandingZones Management Group                     │    │
│  │  Required Tags: Environment, CostCenter, Owner            │    │
│  │  Purpose: Enforce governance and cost tracking            │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

## Custom Roles Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                      Custom RBAC Roles                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CR-AppDeployer-ResourceGroup-Prod                     │     │
│  │                                                        │     │
│  │  Purpose: CI/CD pipelines for Prod deployments        │     │
│  │  Scope: Prod Management Group                         │     │
│  │                                                        │     │
│  │  Can:                                                  │     │
│  │  ✅ Deploy ARM templates                              │     │
│  │  ✅ Create/modify resources (VMs, Storage, SQL, etc.) │     │
│  │  ✅ Read/write Key Vault secrets                      │     │
│  │  ✅ Manage monitoring and logging                     │     │
│  │                                                        │     │
│  │  Cannot:                                               │     │
│  │  ❌ Assign roles (Microsoft.Authorization/*/write)    │     │
│  │  ❌ Delete resource groups                            │     │
│  │  ❌ Delete/modify virtual networks                    │     │
│  │  ❌ Modify Key Vault access policies                  │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CR-AppDeployer-ResourceGroup-NonProd                  │     │
│  │                                                        │     │
│  │  (Same as Prod, scoped to NonProd MG)                 │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CR-SecurityReader-Enterprise                          │     │
│  │                                                        │     │
│  │  Purpose: Security team compliance and auditing       │     │
│  │  Scope: LandingZones Management Group                 │     │
│  │                                                        │     │
│  │  Can:                                                  │     │
│  │  ✅ Read all resource properties                      │     │
│  │  ✅ Read role assignments and PIM settings            │     │
│  │  ✅ Read Azure Policy compliance                      │     │
│  │  ✅ Read Key Vault secrets (DataAction)               │     │
│  │  ✅ Read security settings                            │     │
│  │                                                        │     │
│  │  Cannot:                                               │     │
│  │  ❌ Modify any resources (read-only)                  │     │
│  └────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline Integration

```
┌────────────────────────────────────────────────────────────────────┐
│                    Azure DevOps Pipeline Flow                      │
│                                                                    │
│  Developer pushes changes to Git repository                       │
│                    │                                               │
│                    ▼                                               │
│         ┌──────────────────────┐                                  │
│         │   Stage 1: Validate  │                                  │
│         │   • terraform fmt    │                                  │
│         │   • terraform validate│                                 │
│         │   • tflint           │                                  │
│         │   • checkov          │                                  │
│         └──────────┬───────────┘                                  │
│                    │                                               │
│                    ▼                                               │
│         ┌──────────────────────┐                                  │
│         │   Stage 2: Plan      │                                  │
│         │   • terraform init   │                                  │
│         │   • terraform plan   │                                  │
│         │   • Save plan file   │                                  │
│         │   • Parse RBAC       │                                  │
│         │     changes          │                                  │
│         └──────────┬───────────┘                                  │
│                    │                                               │
│                    ▼                                               │
│         ┌──────────────────────┐                                  │
│         │  Stage 3: Approval   │                                  │
│         │  Manual gate:        │                                  │
│         │  • Security team     │                                  │
│         │  • Platform team     │                                  │
│         │  Review RBAC changes │                                  │
│         │  Timeout: 7 days     │                                  │
│         └──────────┬───────────┘                                  │
│                    │                                               │
│                    ▼                                               │
│         ┌──────────────────────┐                                  │
│         │   Stage 4: Apply     │                                  │
│         │   • terraform apply  │                                  │
│         │   • Update docs      │                                  │
│         │   • Send summary     │                                  │
│         └──────────────────────┘                                  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Data Flow - User Access Journey

```
┌────────────────────────────────────────────────────────────────────┐
│              End-to-End Access Flow Example                        │
│                                                                    │
│  Scenario: Platform engineer needs to deploy infrastructure       │
│                                                                    │
│  Step 1: User is member of "AZ-ROL-Platform-Owner-Eligible"       │
│                                                                    │
│  Step 2: User activates Owner role via PIM                        │
│          ├─ MFA challenge presented                               │
│          ├─ User provides justification                           │
│          ├─ Approval request sent to Security Team                │
│          └─ Security Team approves                                │
│                                                                    │
│  Step 3: User now has Owner role for 2 hours                      │
│          ├─ Access granted at Platform MG scope                   │
│          └─ Inherits to Identity & Connectivity subs              │
│                                                                    │
│  Step 4: User deploys resources                                   │
│          ├─ Creates resource group                                │
│          ├─ Azure Policy checks tags (required)                   │
│          ├─ Deploys VMs, networking, etc.                         │
│          └─ All actions logged to Activity Log                    │
│                                                                    │
│  Step 5: After 2 hours                                            │
│          ├─ PIM automatically deactivates role                    │
│          ├─ User loses Owner permissions                          │
│          └─ Must re-activate if more work needed                  │
│                                                                    │
│  Step 6: Audit Trail                                              │
│          ├─ PIM activation logged                                 │
│          ├─ Approval recorded                                     │
│          ├─ Resource changes in Activity Log                      │
│          ├─ Azure Policy compliance tracked                       │
│          └─ Monthly access review includes this activation        │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Security Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│                    Security Boundary Model                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Tenant Root Management Group                            │   │
│  │                                                         │   │
│  │ Break-Glass Account Only (permanent Owner)             │   │
│  │ ⚠️ Emergency access only - monitored with alerts       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────┐  ┌─────────────────────────┐    │
│  │ Platform MG              │  │ LandingZones MG         │    │
│  │                          │  │                         │    │
│  │ 🔐 PIM-Eligible Only     │  │ 🔐 Mixed Access Model   │    │
│  │ • Owner (2h, approval)   │  │ • Prod: Reader only     │    │
│  │ • Contributor (4h)       │  │ • Custom Deployer roles │    │
│  │                          │  │ • PIM for consultants   │    │
│  │ Policy: Deny Owner @Sub  │  │ Policy: Deny Owner @Sub │    │
│  └──────────────────────────┘  └─────────────────────────┘    │
│                                                                 │
│  Network Team                    Application Teams             │
│  ✅ Active Contributor           ✅ Active Reader (MG level)   │
│  @ Connectivity MG               ✅ Contributor @ RG level     │
│  (Scoped, no PIM needed)         (Scoped, no PIM needed)       │
│                                                                 │
│  Identity Team                   Security Team                 │
│  ✅ Active Contributor           ✅ Active Security Reader     │
│  @ Identity MG                   @ Platform + LandingZones     │
│  (Scoped, no PIM needed)         (Custom role with KV access)  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Naming Conventions

```
Entra ID Security Groups:
  Format: AZ-ROL-{Scope}-{Role}-{Attribute}

  Examples:
  • AZ-ROL-Platform-Owner-Eligible
  • AZ-ROL-AppTeam-Contributor-Prod
  • AZ-ROL-Security-Reader
  • AZ-ROL-Consultant-Contributor-Temp

Custom Roles:
  Format: CR-{Function}-{Scope}

  Examples:
  • CR-AppDeployer-ResourceGroup-Prod
  • CR-SecurityReader-Enterprise

Management Groups:
  Format: {Purpose} or {Environment}

  Examples:
  • Platform
  • Identity
  • Connectivity
  • LandingZones
  • Prod
  • NonProd
```

## Technology Stack

```
┌──────────────────────────────────────────────────────────────┐
│                    Technology Components                     │
│                                                              │
│  Infrastructure as Code:                                    │
│  • Terraform 1.5+ (azurerm provider 3.0+)                  │
│  • Remote state (Azure Storage)                            │
│  • State locking (blob leases)                             │
│                                                              │
│  Identity & Access:                                         │
│  • Entra ID (Azure Active Directory)                       │
│  • Azure AD Premium P2 (required for PIM)                  │
│  • PIM for Azure Resources                                 │
│  • RBAC (Role-Based Access Control)                        │
│                                                              │
│  Governance:                                                │
│  • Azure Policy                                            │
│  • Management Groups                                        │
│  • Activity Logs                                           │
│  • Azure Resource Graph (queries)                          │
│                                                              │
│  CI/CD:                                                     │
│  • Azure DevOps Pipelines                                  │
│  • Git (version control)                                   │
│  • Service Principal authentication                        │
│                                                              │
│  Monitoring & Compliance:                                   │
│  • Azure Monitor                                           │
│  • Log Analytics                                           │
│  • Compliance dashboard                                    │
│  • PIM audit logs                                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## High-Availability & Disaster Recovery

```
Break-Glass Access:
  • Account: breakglass@domain.com
  • Role: Owner @ Tenant Root (permanent)
  • Storage: Physical safe (NOT Azure Key Vault)
  • Excluded from: Conditional Access
  • Alert: Any usage triggers immediate alert
  • Testing: Quarterly

Terraform State Backup:
  • Storage: Azure Storage with versioning enabled
  • Retention: 30 days of versions
  • Backup: Daily automated snapshots
  • Recovery: Import existing resources if needed

Rollback Procedures:
  • PIM configuration: Documented revert steps
  • Policy assignments: Can be disabled without deletion
  • Role assignments: Terraform state includes previous versions
  • Git: All changes version controlled with full history
```

## Compliance & Audit Touchpoints

```
┌───────────────────────────────────────────────────────────────┐
│                    Audit & Compliance Layer                   │
│                                                               │
│  Daily:                                                       │
│  • Review PIM activation requests                            │
│  • Approve/deny privilege escalations                        │
│                                                               │
│  Weekly:                                                      │
│  • Review PIM activation log (past 7 days)                   │
│  • Check Azure Policy compliance dashboard                   │
│  • Verify no permanent Owner assignments                     │
│                                                               │
│  Monthly:                                                     │
│  • Review Entra ID group memberships                         │
│  • Audit all role assignments                                │
│  • Renew expiring PIM eligible assignments (auto via TF)     │
│                                                               │
│  Quarterly:                                                   │
│  • Test break-glass account access                           │
│  • Review and update custom roles                            │
│  • Assess PIM policy effectiveness                           │
│  • Full access review (remove stale access)                  │
│                                                               │
│  Evidence Sources:                                            │
│  • Azure Activity Log (all RBAC changes)                     │
│  • PIM audit log (activations, approvals)                    │
│  • Azure Policy compliance reports                           │
│  • Git commit history (Terraform changes)                    │
│  • Azure DevOps pipeline logs (approval gates)               │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## References

- Azure Management Groups: [https://learn.microsoft.com/azure/governance/management-groups/](https://learn.microsoft.com/azure/governance/management-groups/)
- PIM for Azure Resources: [https://learn.microsoft.com/azure/active-directory/privileged-identity-management/](https://learn.microsoft.com/azure/active-directory/privileged-identity-management/)
- Azure RBAC Best Practices: [https://learn.microsoft.com/azure/role-based-access-control/best-practices](https://learn.microsoft.com/azure/role-based-access-control/best-practices)
- Azure Policy: [https://learn.microsoft.com/azure/governance/policy/](https://learn.microsoft.com/azure/governance/policy/)

---

**Last Updated:** 2026-03-03
**Version:** 1.0
