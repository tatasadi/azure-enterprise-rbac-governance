# Operational Runbook

## Purpose

This runbook provides step-by-step procedures for common operational tasks related to Azure RBAC and PIM governance. It is intended for platform engineers, security team members, and anyone managing Azure access.

---

## Table of Contents

1. [How to Activate a PIM Role](#1-how-to-activate-a-pim-role)
2. [How to Approve a PIM Activation Request](#2-how-to-approve-a-pim-activation-request)
3. [How to Request a New Role Assignment](#3-how-to-request-a-new-role-assignment)
4. [How to Add a User to an Entra ID Group](#4-how-to-add-a-user-to-an-entra-id-group)
5. [How to Troubleshoot "Access Denied" Errors](#5-how-to-troubleshoot-access-denied-errors)
6. [How to Review PIM Activation History](#6-how-to-review-pim-activation-history)
7. [How to Handle Emergency Access (Break-Glass)](#7-how-to-handle-emergency-access-break-glass)
8. [How to Deploy RBAC Changes via Terraform](#8-how-to-deploy-rbac-changes-via-terraform)
9. [How to Create a Policy Exemption](#9-how-to-create-a-policy-exemption)
10. [How to Perform Quarterly Access Review](#10-how-to-perform-quarterly-access-review)
11. [How to Onboard a New Application Team](#11-how-to-onboard-a-new-application-team)
12. [How to Offboard an Employee](#12-how-to-offboard-an-employee)
13. [How to Test the Break-Glass Account](#13-how-to-test-the-break-glass-account)
14. [How to Investigate Suspicious PIM Activation](#14-how-to-investigate-suspicious-pim-activation)
15. [Troubleshooting Common Issues](#15-troubleshooting-common-issues)

---

## 1. How to Activate a PIM Role

**Scenario:** You need Owner or Contributor access to perform privileged operations.

### Prerequisites
- You are a member of a PIM-eligible group (e.g., `AZ-ROL-Platform-Owner-Eligible`)
- You have Azure MFA configured
- You have a business justification for the access

### Steps

1. **Navigate to PIM**
   - Go to [Azure Portal](https://portal.azure.com)
   - Search for "Privileged Identity Management" or go to Entra ID → Privileged Identity Management

2. **Access My Roles**
   - Click **My roles** in the left navigation
   - Click **Azure resources** tab

3. **Find Your Eligible Role**
   - You should see roles you're eligible for (e.g., "Owner" at "Platform" management group)
   - If you don't see any eligible roles, verify you're a member of the appropriate group

4. **Activate the Role**
   - Click **Activate** next to the role you need

5. **Fill Out Activation Form**
   - **Duration:** Select how long you need access (max 2h for Owner, 4h for Contributor)
   - **Justification:** Provide clear business reason (e.g., "Deploying VNet changes for project X")
   - **Ticket number:** (Optional) Include incident or change ticket number
   - Click **Activate**

6. **Complete MFA Challenge**
   - Azure will prompt for MFA authentication
   - Complete the MFA challenge

7. **Wait for Approval (Owner role only)**
   - For Owner role: Your request is sent to approvers (Security + Platform team)
   - You'll receive email notification when approved or denied
   - Approval typically takes 5-15 minutes during business hours
   - For Contributor role: Activation is automatic (no approval needed)

8. **Confirmation**
   - Once approved/activated, you'll receive email confirmation
   - The role is now active for the specified duration
   - You can verify by checking the "Active assignments" tab

### Expected Duration
- **Contributor (no approval):** 1-2 minutes
- **Owner (with approval):** 5-30 minutes depending on approver availability

### Troubleshooting
- **"You are not eligible for this role":** Verify group membership
- **"MFA failed":** Ensure MFA is properly configured in your account
- **Activation timed out:** Eligibility may have expired; contact platform team

---

## 2. How to Approve a PIM Activation Request

**Scenario:** You are an approver and received a notification about a PIM activation request.

### Prerequisites
- You are designated as a PIM approver (Security Team or Platform Team Lead)
- You received an email or portal notification about pending request

### Steps

1. **Access Pending Requests**
   - Go to [Azure Portal](https://portal.azure.com) → Entra ID → Privileged Identity Management
   - Click **Approve requests** in the left navigation
   - Click **Azure resources** tab

2. **Review Request Details**
   - Click on the pending request to see details:
     - Who is requesting access
     - What role they're requesting (Owner, Contributor, etc.)
     - What scope (which management group/subscription)
     - Duration of access requested
     - Justification provided
     - Ticket number (if provided)

3. **Validate the Request**
   - **Verify identity:** Is this person expected to have this access?
   - **Check justification:** Does the justification make sense?
   - **Validate duration:** Is the requested duration appropriate for the task?
   - **Confirm scope:** Is the scope (MG/subscription) correct?
   - **Cross-reference ticket:** If change ticket provided, verify it exists and is approved

4. **Make Decision**

   **To Approve:**
   - Click **Approve**
   - Provide approval justification (e.g., "Approved per change ticket CHG0012345")
   - Click **Submit**

   **To Deny:**
   - Click **Deny**
   - Provide detailed denial reason (e.g., "No valid change ticket provided")
   - Click **Submit**

5. **Notification**
   - Requestor receives email notification of approval/denial
   - If approved, their role is activated immediately

### Approval Guidelines

**Approve if:**
- ✅ Justification is clear and specific
- ✅ Requestor should have this access (member of correct group)
- ✅ Requested duration is reasonable
- ✅ Change ticket exists (if organization requires)
- ✅ No security concerns about the request

**Deny if:**
- ❌ Justification is vague or missing
- ❌ Requestor shouldn't have this level of access
- ❌ Requested duration is excessive
- ❌ No change ticket when required
- ❌ Suspicious timing (e.g., off-hours with no explanation)
- ❌ Recent similar activation (possible repeated failed attempts)

**Escalate if:**
- ⚠️ Request is unusual or suspicious
- ⚠️ You're unsure about the requester's role
- ⚠️ Large-scale changes with minimal justification

### Expected Duration
- Review and approve/deny within **15 minutes** during business hours
- For off-hours requests, approval within **1 hour** (escalation process)

### Troubleshooting
- **Cannot see pending requests:** Verify you're assigned as approver in PIM settings
- **Request already approved:** Another approver may have acted first

---

## 3. How to Request a New Role Assignment

**Scenario:** You need a new role assignment that doesn't currently exist.

### Prerequisites
- Business justification for the access
- Manager approval
- Understanding of least-privilege principle

### Steps

1. **Determine Access Requirements**
   - What role do you need? (Owner, Contributor, Reader, Custom)
   - What scope? (Management Group, Subscription, Resource Group)
   - Permanent or temporary access?
   - Should it be PIM-eligible or active assignment?

2. **Create Access Request Ticket**
   - Open a ticket with IT/Platform team (use your organization's ticketing system)
   - Include:
     - Your name and email
     - Role needed (Owner, Contributor, etc.)
     - Scope (specific MG/subscription/RG)
     - Business justification
     - Duration (permanent or time-limited)
     - Manager approval

3. **Security Review**
   - Security team reviews the request
   - May request additional justification or clarification
   - Validates least-privilege principle is followed

4. **Platform Team Implementation**
   - Platform team creates Terraform code changes:
     - Updates `rbac/group-assignments.tf` with new role assignment
     - Creates new Entra ID group if needed
   - Creates Pull Request in Git repository
   - PR includes description of the change and ticket reference

5. **Approval Workflow**
   - Platform team + Security team review PR
   - Azure DevOps pipeline runs `terraform plan`
   - RBAC changes are highlighted in pipeline output
   - Approvers review and approve pipeline

6. **Deployment**
   - Pipeline applies Terraform changes
   - Role assignment is created in Azure
   - Requestor is added to appropriate Entra ID group

7. **Confirmation**
   - Requestor receives notification that access is granted
   - Requestor can verify by checking Azure Portal → Access Control (IAM) or PIM

### Expected Duration
- Simple requests: 1-2 business days
- Complex/privileged requests: 3-5 business days (additional reviews)

### Approval Matrix

| Role | Scope | Approvers Required |
|------|-------|-------------------|
| Reader | Any | Manager + Platform Team |
| Contributor | Resource Group | Manager + Platform Team |
| Contributor | Subscription/MG | Manager + Platform Team + Security Team |
| Owner | Any | Manager + Platform Lead + Security Lead + CISO |
| Custom Role | Any | Manager + Platform Team + Security Team |

---

## 4. How to Add a User to an Entra ID Group

**Scenario:** You need to grant someone access by adding them to an RBAC group.

### Prerequisites
- You have permission to manage group membership (Group Owner or appropriate admin role)
- User has an Entra ID account
- Approval from appropriate authority (see approval matrix in previous section)

### Steps

1. **Navigate to Entra ID Groups**
   - Go to [Azure Portal](https://portal.azure.com)
   - Navigate to Entra ID → Groups

2. **Find the Group**
   - Search for the group name (e.g., `AZ-ROL-Platform-Contributor-Eligible`)
   - Click on the group name

3. **Add Member**
   - Click **Members** in the left navigation
   - Click **+ Add members**
   - Search for the user by name or email
   - Select the user from the results
   - Click **Select**

4. **Verify Addition**
   - User should now appear in the members list
   - It may take 5-10 minutes for group membership to propagate

5. **Notify User**
   - Inform the user they've been added to the group
   - If it's a PIM-eligible group, direct them to the PIM activation runbook (Section 1)

### Important Notes

- **PIM-eligible groups:** Adding user to group makes them *eligible* to activate the role, not automatically active
- **Active assignment groups:** Adding user to group grants access immediately
- **Propagation delay:** Group membership changes can take up to 5 minutes to take effect
- **Terraform-managed groups:** Some groups may be managed by Terraform; adding manually will cause drift (prefer Terraform changes)

### Preferred Method (via Terraform)

For production environments, group membership should be managed via Terraform:

1. Update `rbac/entra-groups.tf` to add `members` attribute
2. Create PR with the change
3. Follow approval workflow
4. Deploy via pipeline

---

## 5. How to Troubleshoot "Access Denied" Errors

**Scenario:** You're getting "Access Denied" or "Forbidden" errors in Azure.

### Diagnostic Steps

#### Step 1: Verify Your Current Roles

1. Navigate to the resource (subscription, RG, etc.) where you're getting access denied
2. Click **Access Control (IAM)**
3. Click **Check access**
4. Search for your name
5. Review what roles you currently have

#### Step 2: Check PIM Activation Status

1. Go to PIM → My roles → Azure resources
2. Check **Active assignments** tab
3. Verify the role you think you have is actually active (not just eligible)
4. If role is eligible but not active, you need to activate it (see Section 1)

#### Step 3: Verify Group Membership

1. Go to Entra ID → Users → [Your User] → Groups
2. Verify you're a member of the expected RBAC group
3. If not, request group membership (see Section 3)

#### Step 4: Check Scope of Assignment

1. Your role may be assigned at a different scope than you expect
2. Example: You have Contributor at Resource Group level, but trying to create a resource group (requires subscription level)
3. Verify the scope of your role assignment matches where you're trying to perform the action

#### Step 5: Propagation Delay

1. If you were just added to a group or just activated PIM, wait 5-10 minutes
2. Sign out and sign back in to Azure Portal
3. Try again

#### Step 6: Azure Policy Blocks

1. You may have the RBAC permission but Azure Policy is denying the action
2. Check for policy violations in the error message
3. Common policy blocks:
   - Trying to assign Owner role at subscription level (blocked by policy)
   - Missing required tags on resource group
   - Attempting to create resources in unauthorized regions

### Common Scenarios

#### Scenario A: "Cannot create resource group"

**Likely cause:** You have Contributor at Resource Group level, not Subscription level

**Solution:**
- Resource groups require Contributor at *subscription* or *management group* level
- Request subscription-level access or ask platform team to create RG for you

#### Scenario B: "Cannot assign roles"

**Likely cause:** You have Contributor role, but role assignments require Owner or User Access Administrator

**Solution:**
- Activate Owner role via PIM (if you're eligible)
- Or request Owner role activation from someone who has it

#### Scenario C: "Policy denied your request"

**Likely cause:** Azure Policy is blocking the action (even though you have RBAC permission)

**Solution:**
- Review the policy violation message
- Adjust your action to comply with policy (e.g., add required tags)
- Or request policy exemption if legitimate exception (see Section 9)

#### Scenario D: "PIM role not working"

**Likely cause:** Role activation expired or wasn't fully activated

**Solution:**
- Check PIM → My roles → Active assignments
- If role is not listed as active, activate it again
- Verify activation was approved (for Owner role)

---

## 6. How to Review PIM Activation History

**Scenario:** You need to audit who has activated privileged roles.

### Prerequisites
- Security Reader or appropriate admin role
- Access to Azure Portal and/or Log Analytics

### Method 1: Azure Portal (Last 30 Days)

1. **Navigate to PIM**
   - Go to Azure Portal → Entra ID → Privileged Identity Management

2. **Access Audit History**
   - Click **Azure resources** in the left navigation
   - Click **Resource audit** (shows all PIM activities)

3. **Filter Results**
   - Filter by:
     - Date range (last 7 days, 30 days, etc.)
     - Activity type (Activate role, Approve activation, etc.)
     - User name
     - Role name
     - Resource (management group/subscription)

4. **Review Details**
   - Click on specific activation to see:
     - Who activated the role
     - What role was activated
     - Duration of activation
     - Justification provided
     - Who approved it
     - Timestamp

### Method 2: Azure Resource Graph (Custom Queries)

For more detailed or historical analysis:

```kusto
// Query PIM activations in the last 7 days
authorizationresources
| where type == "microsoft.authorization/roleassignments"
| where properties.scope contains "managementGroups"
| extend roleDefinitionId = tostring(properties.roleDefinitionId)
| extend principalId = tostring(properties.principalId)
| extend scope = tostring(properties.scope)
| where roleDefinitionId contains "8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // Owner role
| project principalId, scope, roleDefinitionId, properties
```

### Method 3: Log Analytics (Long-Term Retention)

If Azure Activity Logs are exported to Log Analytics:

```kusto
AzureActivity
| where OperationNameValue == "Microsoft.Authorization/roleAssignments/write"
| where ActivityStatusValue == "Success"
| where Properties contains "PIM"
| extend Caller = tostring(parse_json(Authorization).evidence.principalId)
| extend Role = tostring(parse_json(Authorization).evidence.role)
| project TimeGenerated, Caller, Role, ResourceGroup, SubscriptionId
| order by TimeGenerated desc
```

### Weekly Review Checklist

- [ ] Review all Owner activations in the past week
- [ ] Verify all activations have justifications
- [ ] Check for unusual activation patterns (e.g., same user activating multiple times)
- [ ] Verify approvals were completed for Owner activations
- [ ] Identify any denied activations and follow up
- [ ] Review activation duration (are people requesting max duration unnecessarily?)

---

## 7. How to Handle Emergency Access (Break-Glass)

**Scenario:** Critical emergency requiring immediate Azure access, and normal PIM process is too slow or unavailable.

### When to Use Break-Glass

**Use break-glass account ONLY when:**
- ✅ Critical outage affecting production systems
- ✅ PIM/Entra ID is unavailable or not responding
- ✅ All PIM approvers are unavailable
- ✅ Security incident requiring immediate action
- ✅ No other way to resolve the emergency in required timeframe

**DO NOT use break-glass for:**
- ❌ Routine operations that can wait for PIM approval
- ❌ Non-emergency changes
- ❌ Convenience (avoiding PIM activation)

### Break-Glass Activation Process

#### Step 1: Declare Emergency

1. Contact on-call manager or incident commander
2. Declare emergency and justify need for break-glass access
3. Document emergency in incident ticket

#### Step 2: Retrieve Credentials

1. Physical access to security office safe:
   - Authorized personnel: CISO, Security Manager, IT Director
   - Safe access is logged in physical log book
2. Retrieve break-glass credential envelope
3. **Log the retrieval:** Record date, time, your name, and reason in log book

#### Step 3: Access Azure

1. Sign in to Azure Portal with break-glass account: `breakglass@[yourdomain].com`
2. Perform **only** the minimum necessary actions to resolve emergency
3. Document all actions taken

#### Step 4: Post-Emergency Actions (Within 24 Hours)

1. **Document everything:**
   - What emergency required break-glass access
   - What actions were taken using break-glass account
   - What changes were made to Azure environment
   - Who authorized the break-glass usage

2. **Update Terraform:**
   - If any role assignments or resources were created manually, update Terraform code to match
   - Run `terraform plan` to verify drift
   - Create PR to align Terraform with actual state

3. **Security Review:**
   - Security team reviews all actions taken with break-glass account
   - Verify no unauthorized actions were performed
   - Review alert logs (break-glass usage should have triggered alerts)

4. **Return Credentials:**
   - Return credential envelope to safe
   - Log the return in log book

5. **Incident Post-Mortem:**
   - Document why break-glass was necessary
   - Identify improvements to prevent future need
   - Update procedures if needed

### Break-Glass Account Monitoring

The following alerts should fire immediately when break-glass account is used:

- ✅ Alert to Security Team email/SMS
- ✅ Alert to CISO
- ✅ Teams/Slack notification to security channel
- ✅ Incident ticket auto-created

### Expected Frequency

- Break-glass should be used < 2 times per year
- Quarterly testing drills don't count as "usage"

---

## 8. How to Deploy RBAC Changes via Terraform

**Scenario:** You need to add, modify, or remove a role assignment via Terraform.

### Prerequisites
- Git repository access
- Terraform knowledge
- Approval from appropriate stakeholders

### Steps

#### Step 1: Create Feature Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/add-rbac-data-team
```

#### Step 2: Make Terraform Changes

Example: Adding a new role assignment

1. Edit `rbac/group-assignments.tf`:

```hcl
resource "azurerm_role_assignment" "data_team_contributor" {
  scope                = data.azurerm_management_group.nonprod.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.data_team_contributor.object_id
  description          = "Data team - Contributor access to NonProd"
}
```

2. If creating a new group, edit `rbac/entra-groups.tf`:

```hcl
resource "azuread_group" "data_team_contributor" {
  display_name     = "AZ-ROL-DataTeam-Contributor-NonProd"
  description      = "Data team - Contributor access to NonProd resources"
  security_enabled = true
  owners           = var.group_owners
}
```

#### Step 3: Test Locally

```bash
cd rbac
terraform init
terraform plan
```

Review the plan output carefully:
- Verify it's creating/modifying the expected resources
- Check for any unexpected deletions
- Ensure no unintended changes

#### Step 4: Commit and Push

```bash
git add rbac/
git commit -m "Add Data Team Contributor role for NonProd

- Created AZ-ROL-DataTeam-Contributor-NonProd group
- Assigned Contributor role at NonProd MG scope
- Ref: Ticket INC0012345"

git push origin feature/add-rbac-data-team
```

#### Step 5: Create Pull Request

1. Go to Git repository (Azure DevOps, GitHub, etc.)
2. Create Pull Request from `feature/add-rbac-data-team` to `main`
3. Fill out PR description:
   - What is changing
   - Why it's needed
   - Reference ticket/approval
   - Tag reviewers (Security Team + Platform Team)

#### Step 6: Pipeline Execution

1. Pipeline automatically triggers on PR creation
2. **Validate stage:** Runs `terraform fmt`, `terraform validate`, linting
3. **Plan stage:** Runs `terraform plan` and highlights RBAC changes
4. Review the pipeline output for RBAC change summary

#### Step 7: Approval Gate

1. Pipeline pauses at Approval stage
2. Approvers receive notification
3. Approvers review:
   - Terraform plan output
   - RBAC change summary
   - PR description and justification
4. Minimum 2 approvers required (Security + Platform representation)
5. Approvers approve or reject

#### Step 8: Apply

1. After approval, pipeline continues to Apply stage
2. Runs `terraform apply` with the saved plan
3. Changes are deployed to Azure
4. Pipeline posts summary of applied changes

#### Step 9: Verify

1. Check Azure Portal to verify role assignment exists
2. If creating PIM-eligible assignment, verify in PIM
3. Notify requestor that access is granted

### Rollback Procedure

If something goes wrong:

```bash
git revert <commit-hash>
git push origin main
```

This triggers the pipeline again, which will reverse the changes.

---

## 9. How to Create a Policy Exemption

**Scenario:** You have a legitimate need to bypass an Azure Policy rule.

### Prerequisites
- Business justification for exemption
- Security team approval
- Temporary exemption preferred over permanent

### Steps

#### Step 1: Validate the Need

Before requesting exemption, verify:
- Is there a way to comply with the policy instead of exempting?
- Is the policy rule correct, or should the policy be updated?
- Is this a one-time need or recurring issue?

#### Step 2: Create Exemption Request Ticket

Open ticket with the following information:
- **Resource:** What resource needs exemption (subscription, RG, specific resource)
- **Policy:** Which policy is blocking you (name and description)
- **Justification:** Why you need to bypass the policy
- **Duration:** How long the exemption is needed (prefer temporary)
- **Alternatives:** What alternatives were considered
- **Risk:** What security risk does the exemption create

#### Step 3: Security Review

- Security team reviews the request
- May request additional information or alternatives
- Security team approves or denies

#### Step 4: Create Exemption in Terraform

1. Edit `policies/main.tf` (or create `policies/exemptions.tf`):

```hcl
resource "azurerm_resource_policy_exemption" "legacy_app_owner_assignment" {
  name                 = "legacy-app-owner-exemption"
  policy_assignment_id = azurerm_management_group_policy_assignment.deny_owner_landingzones.id
  resource_id          = "/subscriptions/${var.subscription_legacy}/resourceGroups/rg-legacy-app"
  exemption_category   = "Waiver" # or "Mitigated"

  display_name = "Legacy app requires Owner at subscription scope"
  description  = "Legacy application requires Owner until migration to PIM completed (target: Q3 2026)"

  # Temporary exemption (90 days)
  expires_on = "2026-06-01T00:00:00Z"

  metadata = jsonencode({
    ticketReference = "INC0012345"
    approver        = "Security Team Lead"
    reviewDate      = "2026-05-01"
  })
}
```

2. Create PR following standard process (Section 8)

#### Step 5: Review and Approval

- Platform + Security teams review the exemption
- Approve via pipeline approval gate
- Deploy via Terraform apply

#### Step 6: Document and Monitor

1. Add exemption to exemption tracking spreadsheet:
   - Resource exempted
   - Policy exempted from
   - Expiration date
   - Owner
   - Review date

2. Set calendar reminder for expiration date
3. Monitor for misuse of exemption

### Exemption Categories

- **Waiver:** Policy requirement isn't applicable to this resource
- **Mitigated:** Risk is mitigated through other controls

### Temporary vs. Permanent Exemptions

**Prefer temporary exemptions:**
- Include `expires_on` parameter
- Default to 90 days
- Require renewal if still needed

**Permanent exemptions:**
- Only for legacy systems that cannot be changed
- Require CISO approval
- Reviewed quarterly

### Exemption Approval Matrix

| Policy Severity | Approvers Required |
|----------------|-------------------|
| Low (Audit policies) | Platform Team |
| Medium (Tag requirements) | Platform Team + Security Team |
| High (RBAC denies) | Platform Team + Security Team + Manager |
| Critical (Security policies) | Platform Team + Security Team + CISO |

---

## 10. How to Perform Quarterly Access Review

**Scenario:** Quarterly access review is due (compliance requirement).

### Prerequisites
- Security Reader or higher access
- Access review schedule (quarterly)
- Stakeholder availability

### Access Review Checklist

#### Phase 1: PIM Eligible Assignments (Week 1)

**Task 1.1: Export Eligible Assignments**

1. Navigate to PIM → Azure resources → Assignments → Eligible assignments
2. Export to CSV (if available) or screenshot
3. Document:
   - Group name
   - Role
   - Scope
   - Expiration date

**Task 1.2: Review Platform Team Eligibility**

- [ ] Review all members of `AZ-ROL-Platform-Owner-Eligible`
- [ ] Verify each member still requires Owner access
- [ ] Check for employees who have changed roles
- [ ] Remove eligibility for anyone who no longer needs it

**Task 1.3: Review Consultant Access**

- [ ] Review all members of `AZ-ROL-Consultant-Contributor-Temp`
- [ ] Verify consultant engagements are still active
- [ ] Remove eligibility for completed engagements
- [ ] Verify 90-day expiration is set correctly

#### Phase 2: Active Role Assignments (Week 2)

**Task 2.1: Export All Role Assignments**

Run Azure Resource Graph query:

```kusto
authorizationresources
| where type == "microsoft.authorization/roleassignments"
| extend roleDefinitionId = tostring(properties.roleDefinitionId)
| extend principalId = tostring(properties.principalId)
| extend scope = tostring(properties.scope)
| project principalId, roleDefinitionId, scope
```

**Task 2.2: Review Privileged Roles**

- [ ] Check for any permanent Owner assignments (should be 0 except break-glass)
- [ ] Review all Contributor assignments at MG/subscription level
- [ ] Verify no direct user assignments (all should be groups)

**Task 2.3: Review Application Team Access**

- [ ] Review members of all `AZ-ROL-AppTeam-*` groups
- [ ] Verify team members are still on the team
- [ ] Check for contractors/temps who may have left
- [ ] Verify resource group scopes are still appropriate

#### Phase 3: Group Membership Review (Week 3)

**Task 3.1: Export Group Memberships**

For each RBAC group:
1. Navigate to Entra ID → Groups → [Group Name] → Members
2. Export member list
3. Contact group owner/manager

**Task 3.2: Manager Certification**

Send to each manager:
- List of employees in their team's RBAC groups
- Request certification that each person still needs access
- Deadline: 1 week

**Task 3.3: Remove Stale Access**

- [ ] Remove users marked for removal by managers
- [ ] Remove users no longer in organization (should be caught by offboarding)
- [ ] Remove guest users whose access period has ended

#### Phase 4: Service Principal Review (Week 3)

**Task 4.1: Review DevOps Service Principals**

- [ ] Review members of `AZ-ROL-DevOps-Deployer-Prod` and `-NonProd`
- [ ] Verify all service principals are still in use
- [ ] Check service principal credential expiration dates
- [ ] Remove unused or expired service principals

**Task 4.2: Review Custom Role Permissions**

- [ ] Review custom role definitions
- [ ] Verify permissions are still appropriate (not too broad)
- [ ] Check if new Azure services need to be added to deployer role
- [ ] Update custom roles if needed

#### Phase 5: Policy Exemption Review (Week 4)

**Task 5.1: Review All Policy Exemptions**

- [ ] List all policy exemptions
- [ ] Verify each exemption still has valid business justification
- [ ] Check expiration dates
- [ ] Remove exemptions no longer needed

**Task 5.2: Review Expiring Exemptions**

- [ ] Identify exemptions expiring in next 30 days
- [ ] Contact owners to verify if renewal is needed
- [ ] Remove exemptions if no longer applicable

#### Phase 6: Documentation and Reporting (Week 4)

**Task 6.1: Generate Access Review Report**

Create report including:
- Total number of role assignments reviewed
- Number of assignments removed
- Number of users removed from groups
- Number of policy exemptions reviewed/removed
- Any security findings or concerns

**Task 6.2: Executive Summary**

Present to leadership:
- Summary of access review findings
- Any security risks identified
- Remediation actions taken
- Recommendations for improvements

**Task 6.3: Update Documentation**

- [ ] Update role matrix if any roles changed
- [ ] Update runbook if processes improved
- [ ] Document lessons learned

### Access Review Schedule

| Quarter | Review Period | Due Date |
|---------|--------------|----------|
| Q1 | Jan 1-31 | Jan 31 |
| Q2 | Apr 1-30 | Apr 30 |
| Q3 | Jul 1-31 | Jul 31 |
| Q4 | Oct 1-31 | Oct 31 |

### Compliance Evidence

Maintain records of:
- Access review reports (PDF)
- Manager certifications (email)
- Remediation actions (Git commits, tickets)
- Executive summary presentations

---

## 11. How to Onboard a New Application Team

**Scenario:** A new application team needs Azure access for their project.

### Prerequisites
- Project approval
- Resource group naming convention
- Budget allocation
- Team lead identified

### Onboarding Checklist

#### Step 1: Gather Requirements (Week 1)

Meet with application team lead to determine:
- [ ] Application name
- [ ] Environment needed (Prod, NonProd, or both)
- [ ] Resource types needed (VMs, App Services, Storage, etc.)
- [ ] Team size
- [ ] List of team members (names and emails)
- [ ] Deployment method (manual, CI/CD)

#### Step 2: Create Resource Groups (Week 1)

1. Determine resource group names:
   - Naming convention: `rg-{appname}-{env}`
   - Example: `rg-customerportal-prod`, `rg-customerportal-nonprod`

2. Create resource groups via Terraform or Portal:
   - Location: [Your region]
   - Tags:
     - Environment: Prod/NonProd
     - CostCenter: [Team's cost center]
     - Owner: [Team lead email]
     - Application: [App name]

#### Step 3: Create Entra ID Groups (Week 1)

If app team doesn't fit into existing `AZ-ROL-AppTeam-*` groups, create new groups:

1. Edit `rbac/entra-groups.tf`:

```hcl
resource "azuread_group" "customerportal_team_prod" {
  display_name     = "AZ-ROL-CustomerPortal-Contributor-Prod"
  description      = "Customer Portal team - Contributor to Prod resource groups"
  security_enabled = true
  owners           = var.group_owners
}

resource "azuread_group" "customerportal_team_nonprod" {
  display_name     = "AZ-ROL-CustomerPortal-Contributor-NonProd"
  description      = "Customer Portal team - Contributor to NonProd resource groups"
  security_enabled = true
  owners           = var.group_owners
}
```

2. Deploy via Terraform (follow Section 8)

#### Step 4: Assign Permissions (Week 2)

1. Edit `rbac/group-assignments.tf`:

```hcl
# Prod resource group access
resource "azurerm_role_assignment" "customerportal_prod" {
  scope                = "/subscriptions/${var.subscription_workload_prod}/resourceGroups/rg-customerportal-prod"
  role_definition_name = "Contributor"
  principal_id         = azuread_group.customerportal_team_prod.object_id
  description          = "Customer Portal team - Contributor to Prod RG"
}

# NonProd resource group access
resource "azurerm_role_assignment" "customerportal_nonprod" {
  scope                = "/subscriptions/${var.subscription_workload_nonprod}/resourceGroups/rg-customerportal-nonprod"
  role_definition_name = "Contributor"
  principal_id         = azuread_group.customerportal_team_nonprod.object_id
  description          = "Customer Portal team - Contributor to NonProd RG"
}

# Reader at MG level for visibility
resource "azurerm_role_assignment" "customerportal_reader_prod" {
  scope                = data.azurerm_management_group.prod.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.customerportal_team_prod.object_id
  description          = "Customer Portal team - Reader for Prod visibility"
}
```

2. Deploy via Terraform

#### Step 5: Add Team Members (Week 2)

1. Add team members to groups:
   - NonProd group: All developers, QA, team lead
   - Prod group: Team lead, senior engineers, DevOps (subset of team)

2. Methods:
   - Via Portal: Entra ID → Groups → Add members
   - Via Terraform: Add `members` attribute (preferred for documentation)

#### Step 6: Setup CI/CD (Week 2-3, if applicable)

If team uses CI/CD:

1. Create service principal for their pipeline
2. Add service principal to appropriate DevOps deployer group:
   - `AZ-ROL-DevOps-Deployer-Prod` (for Prod deployments)
   - `AZ-ROL-DevOps-Deployer-NonProd` (for NonProd deployments)

3. Provide team with service principal credentials (securely)

#### Step 7: Documentation (Week 3)

1. Update role matrix with new groups and assignments
2. Create team-specific documentation:
   - How to access Azure Portal
   - Resource naming conventions
   - Deployment procedures
   - Support contacts

#### Step 8: Training (Week 3)

Conduct onboarding session covering:
- [ ] Azure Portal navigation
- [ ] Resource group structure and naming
- [ ] Tagging requirements
- [ ] Cost management and budgets
- [ ] How to deploy resources
- [ ] How to request additional access
- [ ] Support and escalation procedures

#### Step 9: Handoff (Week 4)

1. Provide team with:
   - Access credentials verified
   - Resource group details
   - Budget allocation
   - Documentation links
   - Support contact information

2. Verify team can successfully:
   - Sign in to Azure Portal
   - See their resource groups
   - Deploy a test resource
   - Access Azure DevOps (if applicable)

### Onboarding Timeline

| Week | Tasks |
|------|-------|
| Week 1 | Gather requirements, create RGs, create groups |
| Week 2 | Assign permissions, add team members, setup CI/CD |
| Week 3 | Documentation, training |
| Week 4 | Handoff, verify access |

---

## 12. How to Offboard an Employee

**Scenario:** An employee is leaving the organization and their Azure access must be revoked.

### Prerequisites
- HR notification of departure
- Departure date
- Manager confirmation

### Offboarding Checklist

#### Immediate Actions (Departure Date)

**Within 1 Hour of Departure:**

1. **Disable Entra ID Account**
   - [ ] HR or IT disables the user's Entra ID account
   - [ ] This immediately blocks Azure access

2. **Revoke Active PIM Activations**
   - [ ] Navigate to PIM → Azure resources → Active assignments
   - [ ] Find any active assignments for the departing user
   - [ ] Click **Remove** to revoke immediately
   - [ ] This is critical if they have an active Owner or Contributor role

3. **Verify MFA Devices Removed**
   - [ ] Entra ID → Users → [User] → Authentication methods
   - [ ] Remove all registered MFA devices

#### Within 24 Hours

4. **Remove from Entra ID Groups**
   - [ ] Navigate to Entra ID → Users → [User] → Groups
   - [ ] Remove from all RBAC groups:
     - Platform teams
     - Application teams
     - Security teams
     - Any PIM-eligible groups
   - [ ] Document which groups they were removed from (for audit)

5. **Review Direct Role Assignments**
   - [ ] Check if user has any direct role assignments (shouldn't, but verify)
   - [ ] Run Azure Resource Graph query:

   ```kusto
   authorizationresources
   | where type == "microsoft.authorization/roleassignments"
   | where properties.principalId == "[USER_OBJECT_ID]"
   ```

   - [ ] Remove any direct assignments found

6. **Review Resource Ownership**
   - [ ] Check if user is listed as Owner on any resources (Tags)
   - [ ] Update Owner tag to new owner (manager or replacement employee)

7. **Revoke Service Principal Access (if applicable)**
   - [ ] If user created service principals, review and remove/reassign ownership
   - [ ] Rotate service principal credentials they may have had access to

#### Within 1 Week

8. **Review PIM Eligibility**
   - [ ] Verify user is removed from all PIM-eligible groups
   - [ ] In Terraform, if user was explicitly listed, remove from members list
   - [ ] Deploy Terraform update

9. **Access Review**
   - [ ] Run report of all role assignments to verify user has none
   - [ ] Check PIM audit log for any activations in last 30 days
   - [ ] Document offboarding in compliance log

10. **Knowledge Transfer**
    - [ ] Identify resources the user created
    - [ ] Transfer ownership/knowledge to replacement
    - [ ] Update documentation with new contacts

### Offboarding Notification Template

**Subject:** Azure Access Offboarding - [Employee Name]

**To:** Platform Team, Security Team

**Message:**
```
Employee Name: [Name]
Last Day: [Date]
Manager: [Manager Name]
Teams: [List of teams/groups]

Actions Required:
1. Remove from Entra ID groups: [List specific groups]
2. Transfer ownership of: [List resources/projects]
3. Knowledge transfer to: [Replacement person]

Offboarding ticket: [Ticket number]
```

### Special Cases

**Immediate Termination (Security Concern):**
- Follow "Immediate Actions" steps immediately
- Revoke all access within 15 minutes
- Change any passwords/credentials they may have known
- Review audit logs for last 30 days of activity
- Alert security team

**Contractor End of Engagement:**
- Remove from consultant PIM-eligible groups
- Verify all temporary exemptions are removed
- Remove from Azure DevOps and any project resources
- Ensure service principal credentials created for them are rotated

---

## 13. How to Test the Break-Glass Account

**Scenario:** Quarterly drill to verify break-glass account works.

### Prerequisites
- Quarterly testing schedule
- Authorized personnel available
- Incident ticket created for testing

### Testing Procedure

#### Step 1: Pre-Test Preparation

1. **Create Test Ticket**
   - Open ticket: "Break-Glass Quarterly Test - Q[X] 2026"
   - Document date and participants

2. **Notify Stakeholders**
   - Email Security Team, CISO, IT Director
   - "Break-glass test scheduled for [Date/Time]"
   - Verify alert monitoring is active

#### Step 2: Retrieve Credentials

1. Authorized person retrieves credentials from physical safe
2. Log retrieval in log book:
   - Date/Time
   - Person retrieving
   - Purpose: "Quarterly test"

#### Step 3: Test Authentication

1. **Open Incognito Browser Window** (to avoid using cached sessions)

2. **Navigate to Azure Portal**
   - Go to https://portal.azure.com

3. **Sign In with Break-Glass Account**
   - Username: `breakglass@[domain].com`
   - Password: [From safe]

4. **Verify MFA is NOT Required**
   - Break-glass should be excluded from MFA/Conditional Access
   - If MFA is prompted, there's a configuration issue

5. **Verify Sign-In Successful**
   - Should reach Azure Portal home page

#### Step 4: Test Permissions

1. **Verify Owner Access at Tenant Root**
   - Navigate to Management Groups
   - Select Tenant Root Management Group
   - Click Access Control (IAM)
   - Verify break-glass account has Owner role

2. **Test Creating a Resource (Non-Impactful)**
   - Navigate to a test subscription
   - Attempt to create a resource group (name: `rg-breakglass-test-[date]`)
   - Verify you can create it (test write permissions)
   - **IMPORTANT:** Delete the test resource group immediately after

3. **Test Role Assignment (Read-Only Check)**
   - Navigate to a management group
   - Click Access Control (IAM) → Add role assignment
   - Verify you can see the role assignment interface
   - **DO NOT actually create a role assignment**
   - Cancel out of the dialog

#### Step 5: Test Alerts

1. **Verify Alert Fired**
   - Check that alert was triggered by break-glass sign-in
   - Expected alerts:
     - Email to Security Team
     - Email to CISO
     - Teams/Slack notification
     - Auto-created incident ticket

2. **Verify Alert Timeliness**
   - Alert should arrive within 2-5 minutes of sign-in

#### Step 6: Sign Out

1. Sign out of Azure Portal
2. Close incognito browser window

#### Step 7: Post-Test Actions

1. **Return Credentials to Safe**
   - Return envelope to safe
   - Log return in log book

2. **Verify Audit Logs**
   - Navigate to Entra ID → Sign-in logs
   - Find break-glass account sign-in
   - Verify it was logged correctly
   - Export log entry for compliance records

3. **Document Test Results**
   - Update test ticket with results:
     - ✅ Credentials retrieved successfully
     - ✅ Sign-in successful
     - ✅ Owner permissions verified
     - ✅ Alerts fired correctly
     - ✅ Audit log captured event

4. **Test Report**
   - Create brief report:
     - Test date
     - Test participants
     - Test results (pass/fail for each step)
     - Any issues identified
     - Remediation actions (if needed)

#### Step 8: Issues and Remediation

**If test fails, investigate:**

| Issue | Possible Cause | Remediation |
|-------|----------------|-------------|
| Cannot sign in | Password incorrect or account disabled | Verify account is enabled; reset password if needed |
| MFA prompted | Conditional Access not excluding break-glass | Update Conditional Access policy |
| No Owner permissions | Role assignment removed or expired | Re-assign Owner at Tenant Root |
| Alerts didn't fire | Alert configuration broken | Fix alert rules |
| Credentials missing from safe | Safe breached or misplaced | Investigate; rotate credentials |

### Testing Schedule

| Quarter | Test Date | Responsible |
|---------|-----------|-------------|
| Q1 | Last week of March | Security Team Lead |
| Q2 | Last week of June | CISO |
| Q3 | Last week of September | IT Director |
| Q4 | Last week of December | Security Team Lead |

### Compliance Documentation

Maintain records of:
- Test tickets (all quarterly tests)
- Test reports (summary of each test)
- Safe access logs (physical log book)
- Alert screenshots (proof alerts fired)
- Audit log exports (sign-in events)

---

## 14. How to Investigate Suspicious PIM Activation

**Scenario:** You receive an alert about a PIM activation that seems unusual or suspicious.

### Indicators of Suspicious Activity

Watch for:
- ⚠️ PIM activation outside business hours (especially 2-6 AM)
- ⚠️ Activation from unusual location (different country)
- ⚠️ Multiple failed activation attempts followed by success
- ⚠️ Vague or missing justification
- ⚠️ User activating role they don't normally use
- ⚠️ Maximum duration requested when not necessary
- ⚠️ Activation shortly after user's account was targeted by phishing

### Investigation Steps

#### Step 1: Initial Assessment (Within 15 Minutes)

1. **Review Activation Details**
   - Go to PIM → Azure resources → Resource audit
   - Find the specific activation
   - Document:
     - User who activated
     - Role activated (Owner, Contributor, etc.)
     - Scope (which MG/subscription)
     - Duration requested
     - Justification provided
     - Timestamp
     - IP address (from sign-in logs)

2. **Check Sign-In Logs**
   - Entra ID → Sign-in logs
   - Find user's recent sign-ins
   - Look for:
     - Unusual locations
     - Impossible travel (e.g., US then Russia 1 hour later)
     - Multiple failed sign-ins
     - Unfamiliar devices

#### Step 2: User Contact (Within 30 Minutes)

**If suspicious indicators present:**

1. **Contact User Directly** (phone call, not email)
   - Ask: "Did you just activate [Role] for [Scope]?"
   - Ask: "Are you currently working on [Justification provided]?"
   - Ask: "Are you at [Location from sign-in log]?"

2. **User Confirms It Was Them:**
   - Document the confirmation
   - Ask for more details about the work
   - Continue monitoring but lower priority

3. **User Denies or Unreachable:**
   - **ESCALATE IMMEDIATELY**
   - Proceed to Step 3

#### Step 3: Immediate Containment (Within 1 Hour)

**If potential compromise detected:**

1. **Revoke Active PIM Role**
   - PIM → Azure resources → Active assignments
   - Find the user's active assignment
   - Click **Remove** to revoke immediately

2. **Disable User Account**
   - Entra ID → Users → [User] → Properties
   - Set "Account enabled" to No
   - This blocks all Azure access immediately

3. **Initiate Password Reset**
   - Force password reset on next sign-in
   - Revoke all refresh tokens

4. **Revoke All Sessions**
   - Entra ID → Users → [User] → Revoke sessions
   - Logs user out of all active sessions

#### Step 4: Forensic Review (Within 2 Hours)

1. **Review All Actions Taken During Activation**

   Azure Activity Log query:
   ```kusto
   AzureActivity
   | where Caller == "[user_principal_name]"
   | where TimeGenerated between (datetime([activation_time]) .. datetime([current_time]))
   | project TimeGenerated, OperationNameValue, ResourceGroup, Resource, ActivityStatusValue
   | order by TimeGenerated asc
   ```

2. **Check for Malicious Actions:**
   - [ ] New role assignments created
   - [ ] Resources deleted
   - [ ] New users created
   - [ ] Service principals created
   - [ ] Secrets accessed in Key Vault
   - [ ] VMs created or accessed
   - [ ] Data exfiltrated from storage accounts

3. **Document Everything:**
   - Screenshot all findings
   - Export activity logs
   - Save sign-in logs
   - Document timeline of events

#### Step 5: Remediation (Within 4 Hours)

**Based on what you found:**

1. **If Malicious Actions Detected:**
   - Remove any role assignments created by attacker
   - Delete any resources created (VMs, storage accounts, etc.)
   - Rotate any credentials that may have been accessed
   - Change service principal secrets
   - Review Key Vault audit logs; rotate secrets if accessed

2. **If No Malicious Actions:**
   - May have been caught before damage done
   - Still rotate user's password as precaution

3. **Containment Validation:**
   - Verify user account is disabled
   - Verify all active PIM roles are revoked
   - Verify no active sessions remain

#### Step 6: Post-Incident Actions

1. **Incident Report:**
   - Create detailed incident report
   - Include timeline, indicators, actions taken
   - Estimate damage/impact
   - Lessons learned

2. **User Remediation:**
   - Security training for the user (if genuine account compromise)
   - Review of security practices
   - MFA device re-registration
   - Account re-enabled only after security review

3. **Process Improvements:**
   - Review PIM policies (should approval be required?)
   - Review Conditional Access policies
   - Consider additional alerts/monitoring

4. **Stakeholder Notification:**
   - CISO briefed on incident
   - Management notification if sensitive data accessed
   - Compliance team notified (may require breach reporting)

### False Positive Scenarios

**Legitimate reasons for "suspicious" activity:**

- User working from home (different location)
- User traveling for business
- Urgent production issue requiring off-hours work
- Legitimate emergency change

**Always contact user to verify before taking disruptive action.**

### Escalation Path

| Severity | Escalation |
|----------|-----------|
| Low: Unusual but user confirms | Document and monitor |
| Medium: Cannot reach user | Revoke PIM role, contact manager |
| High: User denies + malicious actions | Disable account, CISO notification, incident response team |
| Critical: Data breach suspected | Full incident response, legal, compliance, PR |

---

## 15. Troubleshooting Common Issues

### Issue: Terraform State Lock

**Symptoms:** `terraform apply` fails with "state locked" error

**Cause:** Another terraform operation is running, or previous operation didn't release lock

**Solution:**

1. Check if another pipeline is running:
   - Azure DevOps → Pipelines → Check for in-progress runs

2. If no pipeline running, manually break lock:
   ```bash
   terraform force-unlock [LOCK_ID]
   ```

   (Lock ID is shown in the error message)

3. If that fails, go to Azure Storage Account → Blob Container → tfstate → Check for lease
   - Break the lease if needed

**Prevention:** Always let pipelines complete; don't cancel mid-run

---

### Issue: "Insufficient Privileges" When Creating PIM Eligible Assignment

**Symptoms:** Terraform fails when creating `azurerm_pim_eligible_role_assignment`

**Cause:** Service principal running Terraform doesn't have "User Access Administrator" or "Owner" at the required scope

**Solution:**

1. Verify service principal has Owner or User Access Administrator role at Management Group level
2. Check that the role is **active**, not eligible
3. Update service principal role assignment if needed

---

### Issue: Policy Exemption Not Working

**Symptoms:** Policy still denying action even though exemption was created

**Cause:** Exemption may not have applied yet, or scope is incorrect

**Solution:**

1. Verify exemption scope matches the resource being exempted:
   - Exemption scope must be the resource itself or a parent scope

2. Wait 5-10 minutes for exemption to propagate

3. Verify exemption in Azure Policy:
   - Azure Policy → Exemptions → Find your exemption
   - Check status is "Active"

4. If exemption still not working:
   - Check policy assignment scope vs. exemption scope
   - Verify policy assignment ID in exemption is correct

---

### Issue: User Cannot See Resource Groups

**Symptoms:** User has Contributor role but cannot see resource groups in Portal

**Cause:** Role is assigned at Resource Group level, not Subscription level

**Solution:**

This is by design if user has RG-scoped access. To see the resource group:

1. User must navigate directly to the resource group:
   - Azure Portal → Resource Groups → [Type RG name]

2. Or grant Reader role at Subscription/MG level for visibility:
   - Add user to appropriate Reader group
   - This allows browsing without write permissions

---

### Issue: Custom Role Not Available in Portal

**Symptoms:** Cannot find custom role when assigning roles in Portal

**Cause:** Custom role may not have propagated, or scope is incorrect

**Solution:**

1. Verify custom role was created successfully:
   - Azure Portal → Subscriptions → Access Control (IAM) → Roles
   - Filter by "Custom roles"

2. Check assignable scopes:
   - Custom role can only be assigned at scopes listed in `assignable_scopes`
   - If trying to assign at subscription, verify subscription is in assignable scopes

3. Wait 5-10 minutes for custom role to propagate

4. If using Terraform, verify `terraform apply` completed successfully

---

## Contact Information

| Role | Contact | Availability |
|------|---------|--------------|
| Platform Team Lead | platform-lead@company.com | Business hours |
| Security Team Lead | security-lead@company.com | Business hours |
| CISO | ciso@company.com | Escalation only |
| On-Call Engineer | [On-call phone] | 24/7 |
| Helpdesk | helpdesk@company.com | Business hours |

---

## Appendix: Useful Azure CLI Commands

### List All Role Assignments for a User

```bash
az role assignment list --assignee user@domain.com --all --output table
```

### List All Members of a Group

```bash
az ad group member list --group "AZ-ROL-Platform-Owner-Eligible" --output table
```

### Check Policy Compliance

```bash
az policy state list --subscription [subscription-id] --filter "complianceState eq 'NonCompliant'" --output table
```

### View PIM Eligible Assignments (via Graph API)

```bash
az rest --method GET --url "https://graph.microsoft.com/v1.0/roleManagement/directory/roleEligibilitySchedules"
```

---

**Last Updated:** 2026-03-03
**Version:** 1.0
**Maintained By:** Platform Team
**Review Frequency:** Quarterly
