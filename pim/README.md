# Privileged Identity Management (PIM) Configuration

## Overview

PIM configuration is primarily done through the Azure Portal due to limited Terraform support for PIM policies. This directory contains documentation and configuration templates for PIM settings.

## Prerequisites

- Azure AD Premium P2 license
- Privileged Role Administrator or Global Administrator role
- Management Groups and RBAC groups already deployed

## Groups Configured for PIM

Based on the RBAC module, these groups should be configured as **eligible assignments** in PIM:

1. **AZ-ROL-Platform-Owner-Eligible**
   - Role: Owner
   - Scope: Platform Management Group
   - Max duration: 2 hours
   - Approval: Required
   - MFA: Required

2. **AZ-ROL-Platform-Contributor-Eligible**
   - Role: Contributor
   - Scope: Platform Management Group
   - Max duration: 2 hours
   - Approval: Optional
   - MFA: Required

3. **AZ-ROL-Consultant-Contributor-Temp**
   - Role: Contributor
   - Scope: LandingZones Management Group
   - Max duration: 2 hours
   - Approval: Required
   - MFA: Required
   - Eligibility expiration: 90 days

## PIM Configuration Steps (Manual)

### Step 1: Navigate to PIM

1. Go to Azure Portal → Entra ID → Privileged Identity Management
2. Click **Azure resources** in the left navigation
3. Click **Discover resources**
4. Select your Management Groups to onboard them to PIM

### Step 2: Configure Role Settings (Platform Owner)

1. Navigate to the **Platform** Management Group in PIM
2. Click **Settings** → Find **Owner** role → Click **Edit**
3. Configure the following settings:

#### Activation Settings:
```
Maximum activation duration: 2 hours
On activation, require: Azure MFA
Require justification on activation: Yes
Require ticket information on activation: No (Optional)
Require approval to activate: Yes
Select approvers: [Security team members]
```

#### Assignment Settings:
```
Allow permanent eligible assignment: No
Expire eligible assignments after: 180 days
Allow permanent active assignment: No
Expire active assignments after: 30 days
Require justification on active assignment: Yes
Require Azure Multi-Factor Authentication on active assignment: Yes
```

#### Notification Settings:
```
Send notifications when members are assigned as eligible to this role:
- Role assignment alert: Admins
- Notification to assigned user: Yes

Send notifications when members are assigned as active to this role:
- Role assignment alert: Admins
- Notification to assigned user: Yes

Send notifications when eligible members activate this role:
- Role activation alert: Approvers, Admins
- Notification to activated user: Yes
- Request approval notification: Approvers
```

### Step 3: Create Eligible Assignments

1. In PIM, navigate to **Assignments** → **Eligible assignments**
2. Click **+ Add assignments**
3. Select the role (e.g., Owner)
4. Select members: Choose the Entra ID group (e.g., AZ-ROL-Platform-Owner-Eligible)
5. Set assignment duration: 180 days (will require renewal)
6. Click **Assign**

Repeat for:
- Platform Contributor → AZ-ROL-Platform-Contributor-Eligible
- Consultant access → AZ-ROL-Consultant-Contributor-Temp (90 days)

### Step 4: Remove Permanent Assignments (Migration)

⚠️ **CRITICAL: Only do this after confirming eligible assignments work!**

1. Navigate to **Assignments** → **Active assignments**
2. Review all permanent Owner/Contributor assignments
3. For each user with permanent access:
   - Add them to the appropriate Entra ID group
   - Confirm they can activate via PIM
   - Remove the permanent assignment
4. Document all removed assignments

## Testing PIM Activation

### As a User - Activate Owner Role:

1. Go to Azure Portal → Entra ID → Privileged Identity Management
2. Click **My roles** → **Azure resources**
3. Find the **Owner** role at Platform Management Group scope
4. Click **Activate**
5. Fill in:
   - Duration: Up to 2 hours
   - Justification: "Deploying infrastructure updates"
   - (Optional) Ticket number
6. Click **Activate**
7. If approval required, wait for approver notification
8. Once approved, the role is active for the specified duration

### As an Approver - Approve Activation:

1. Receive email notification of pending request
2. Go to PIM → **Approve requests** → **Azure resources**
3. Review the request details
4. Click **Approve** or **Deny**
5. Provide justification
6. User receives notification of approval/denial

## PIM Policy Templates

### Owner Role Policy (Platform Management Group)

| Setting | Value |
|---------|-------|
| Max activation duration | 2 hours |
| Require MFA on activation | Yes |
| Require justification | Yes |
| Require approval | Yes |
| Approvers | Security Team + Platform Leads |
| Eligible assignment expiration | 180 days |
| Active assignment expiration | Not allowed |

### Contributor Role Policy (Platform Management Group)

| Setting | Value |
|---------|-------|
| Max activation duration | 4 hours |
| Require MFA on activation | Yes |
| Require justification | Yes |
| Require approval | No |
| Eligible assignment expiration | 180 days |
| Active assignment expiration | 30 days (exceptions only) |

### Consultant Access Policy (LandingZones)

| Setting | Value |
|---------|-------|
| Max activation duration | 2 hours |
| Require MFA on activation | Yes |
| Require justification | Yes |
| Require approval | Yes |
| Approvers | Security Team |
| Eligible assignment expiration | 90 days |
| Active assignment expiration | Not allowed |

## Monitoring & Compliance

### Weekly Review Tasks:

1. Review PIM activations from past week
2. Check for anomalous activation patterns
3. Verify all activations have justifications
4. Check for expired eligible assignments needing renewal

### Run this query in Azure Resource Graph:

```kusto
// PIM Activations in last 7 days
authorizationresources
| where type == "microsoft.authorization/roleassignments"
| where properties.scope contains "managementGroups"
| extend roleDefinitionId = tostring(properties.roleDefinitionId)
| extend principalId = tostring(properties.principalId)
| extend scope = tostring(properties.scope)
| where roleDefinitionId contains "8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // Owner role
| project principalId, scope, roleDefinitionId
```

## Break-Glass Account

⚠️ **Set this up BEFORE migrating to PIM!**

1. Create emergency access account: `breakglass@yourdomain.com`
2. Assign permanent Owner at Tenant Root Management Group
3. Store credentials in physical safe (not Azure Key Vault!)
4. Exclude from Conditional Access policies
5. Test quarterly
6. Set up alerting for any use of this account

## Rollback Procedure

If PIM causes access issues:

1. Sign in with break-glass account
2. Navigate to affected management group → Access Control (IAM)
3. Add affected users back with permanent assignments
4. Document the issue
5. Review PIM configuration for the problem
6. Fix the issue and test again

## Terraform Limitation Note

Terraform has limited support for PIM. The following must be done manually:

- ✅ Create Entra ID groups (done via Terraform in rbac module)
- ✅ Create role assignments (done via Terraform, converted to eligible in Portal)
- ❌ Configure PIM eligibility (manual in Portal)
- ❌ Configure PIM policies (manual in Portal)
- ❌ Set up approval workflows (manual in Portal)

## Future Enhancement

Consider these tools for PIM automation:

- Azure CLI: Limited PIM support
- PowerShell: `Az.Resources` module has some PIM cmdlets
- Microsoft Graph API: Most complete PIM API
- Azure DevOps: Could use Graph API in pipeline

## References

- [PIM for Azure resources](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-resource-roles-overview)
- [Configure PIM settings](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-resource-roles-configure-role-settings)
- [Approve PIM requests](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-resource-roles-approval-workflow)
