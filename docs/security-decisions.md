# Security Decision Log

## Purpose

This document records all major security decisions made during the design and implementation of the Azure RBAC & PIM governance model. Each decision includes context, rationale, trade-offs, and alternatives considered.

---

## Decision 1: No Permanent Owner Assignments

**Date:** 2026-03-01
**Decision Maker:** Security Team Lead + Platform Team Lead
**Status:** ✅ Approved and Implemented

### Context

The existing Azure environment had 20+ permanent Owner role assignments across various subscriptions, creating significant security risk. Users had standing privileged access that was rarely needed on a daily basis.

### Decision

**All Owner roles must be PIM-eligible with maximum 2-hour activation duration. No permanent Owner assignments except for break-glass account.**

### Rationale

1. **Reduced blast radius:** If an account is compromised, the attacker doesn't automatically have Owner privileges
2. **Just-in-time access:** Users only elevate privileges when needed, reducing exposure window
3. **Improved audit trail:** Every activation is logged with justification and approval
4. **Compliance requirement:** Aligns with CIS Azure Foundations Benchmark and zero standing privileges model
5. **Accountability:** Forces users to justify privileged access before each use

### Trade-offs

**Cons:**
- Slight inconvenience for platform team (must activate role before privileged operations)
- Requires Azure AD Premium P2 license (additional cost)
- Approval workflow can delay emergency operations (mitigated by break-glass account)
- Users must plan ahead for maintenance windows

**Pros:**
- Significantly improved security posture
- Complete audit trail of privileged operations
- Reduced risk of accidental misconfiguration
- Compliance with industry best practices

### Alternatives Considered

1. **Permanent with MFA only**
   - Rejected: MFA doesn't prevent misuse by legitimate user or compromised session

2. **8-hour activation window**
   - Rejected: Too long - defeats purpose of just-in-time access

3. **PIM without approval**
   - Rejected: Approval adds accountability and prevents impulsive actions

4. **Conditional Access only**
   - Rejected: Doesn't provide time-limited access or approval workflow

### Implementation Notes

- PIM eligible assignments managed via Terraform (`azurerm_pim_eligible_role_assignment`)
- Activation policies configured in Azure Portal (2h max, approval required, MFA required)
- Break-glass account created with permanent Owner at Tenant Root (emergency access)

### Success Metrics

- ✅ 0 permanent Owner assignments (except break-glass)
- ✅ 100% of Owner activations require MFA and approval
- ✅ Average activation time < 5 minutes (user experience)
- ✅ < 2% rejection rate on activation requests

---

## Decision 2: Group-Based RBAC Only (Zero Direct User Assignments)

**Date:** 2026-03-01
**Decision Maker:** Platform Team Lead
**Status:** ✅ Approved and Implemented

### Context

Previous RBAC model included both direct user assignments and group-based assignments, creating management complexity and inconsistency.

### Decision

**All RBAC assignments must use Entra ID security groups. Direct user-to-role assignments are prohibited.**

### Rationale

1. **Simplified management:** Add/remove users from groups instead of managing individual role assignments
2. **Consistency:** Single source of truth for access (group membership)
3. **Scalability:** Easier to onboard/offboard users
4. **Auditability:** Group membership changes are logged; easier to review who has access
5. **Policy enforcement:** Azure Policy can audit for direct user assignments
6. **Separation of duties:** Group membership managed separately from role assignments

### Trade-offs

**Cons:**
- Requires creating and maintaining Entra ID groups (overhead)
- Slightly more complex for one-off temporary access (still must use group)
- Group membership changes have slight propagation delay (usually < 5 minutes)

**Pros:**
- Much easier to audit access ("who has Owner?" = "who is in the Owner group?")
- Consistent access model across entire tenant
- Enables group-based PIM (entire group is eligible, not individual users)
- Aligns with Azure landing zone best practices

### Alternatives Considered

1. **Mixed model (some direct, some group-based)**
   - Rejected: Inconsistent, difficult to audit

2. **Direct assignments with strict naming convention**
   - Rejected: Still doesn't solve scalability and audit challenges

3. **Azure AD Privileged Access Groups**
   - Considered: May implement in future for additional security layer

### Implementation Notes

- Created naming convention: `AZ-ROL-{Scope}-{Role}-{Attribute}`
- All groups managed via Terraform (`azuread_group` resource)
- Azure Policy (audit mode) to detect direct user assignments

### Success Metrics

- ✅ 0 direct user-to-role assignments (all via groups)
- ✅ All groups follow naming convention
- ✅ Group membership changes logged and reviewed monthly

---

## Decision 3: Custom Roles for CI/CD Pipelines

**Date:** 2026-03-02
**Decision Maker:** Platform Team Lead + Security Team
**Status:** ✅ Approved and Implemented

### Context

CI/CD service principals previously had Contributor role at subscription level, granting excessive permissions including the ability to delete resource groups and modify network topology.

### Decision

**Create custom roles (CR-AppDeployer-ResourceGroup-Prod/NonProd) for CI/CD pipelines with specific permissions needed for deployment, explicitly denying dangerous actions.**

### Rationale

1. **Least privilege:** Service principals only get permissions needed for deployment
2. **Prevent accidents:** Cannot delete resource groups or virtual networks
3. **Security boundary:** Cannot assign roles or modify Key Vault access policies
4. **Compliance:** Aligns with principle of least privilege
5. **Consistency:** Same role definition for Prod and NonProd (reduces confusion)

### Trade-offs

**Cons:**
- More complex than built-in roles (custom role management required)
- Must update role definition if new Azure services are introduced
- Cannot use at Management Group level if DataActions are added (limitation of Azure RBAC)

**Pros:**
- Significant reduction in service principal privileges
- Prevents accidental deletion of critical infrastructure
- Prevents privilege escalation via role assignments
- Clear audit of exactly what CI/CD can do

### Alternatives Considered

1. **Built-in Contributor role with Azure Policy deny rules**
   - Rejected: Policy can be bypassed; doesn't provide true least privilege

2. **Separate custom roles per application**
   - Rejected: Too granular, management overhead too high

3. **No automation - manual deployments only**
   - Rejected: Not scalable, defeats purpose of DevOps

### Implementation Notes

- Custom roles defined in Terraform (`azurerm_role_definition`)
- Separate roles for Prod and NonProd (allows future differentiation)
- Assigned at Management Group level (inherits to all subscriptions below)
- Service principals added to `AZ-ROL-DevOps-Deployer-Prod/NonProd` groups

### Key Permissions Granted

```
✅ Deploy ARM templates
✅ Create/modify application resources
✅ Read/write Key Vault secrets
✅ Manage monitoring and logging
```

### Key Permissions Denied

```
❌ Assign roles (Microsoft.Authorization/*/write)
❌ Delete resource groups
❌ Delete or modify virtual networks
❌ Modify Key Vault access policies
```

### Success Metrics

- ✅ All CI/CD pipelines use custom role (not Contributor)
- ✅ 0 incidents of accidental resource group deletion
- ✅ Service principals cannot escalate privileges

---

## Decision 4: PIM Activation Approval for Owner Role

**Date:** 2026-03-02
**Decision Maker:** Security Team Lead
**Status:** ✅ Approved and Implemented

### Context

PIM can be configured with or without approval workflow. Approval adds friction but also accountability.

### Decision

**Owner role activations require approval from Security Team. Contributor role activations do not require approval.**

### Rationale

1. **Accountability:** Owner role is highest privilege - approval ensures oversight
2. **Prevents impulsive actions:** Cooling-off period for high-risk changes
3. **Audit trail:** Approver review provides additional documentation
4. **Anomaly detection:** Approvers can identify suspicious activation requests
5. **Balance:** Contributor role doesn't require approval (reduces friction for routine work)

### Trade-offs

**Cons:**
- Approval can delay legitimate work (mitigated by approver availability and break-glass)
- Requires designated approvers to be available
- Risk of approval fatigue if too many requests

**Pros:**
- Strong accountability for Owner-level operations
- Approvers can validate justification matches requested work
- Additional layer of defense against compromised accounts
- Forces users to plan ahead (reduces emergency changes)

### Alternatives Considered

1. **No approval required**
   - Rejected: Loses accountability benefit of PIM

2. **Approval required for all PIM roles (including Contributor)**
   - Rejected: Too much friction for routine operations

3. **Approval based on time of day (e.g., off-hours only)**
   - Considered: May implement in future

4. **Auto-approval if justification matches pattern**
   - Considered: Azure PIM doesn't support this natively yet

### Implementation Notes

- Approvers: Security Team members + Platform Team Leads
- Approval timeout: 4 hours (escalation after 2 hours)
- Approvers receive email and Azure Portal notification
- Approver must provide justification for approval/denial

### Success Metrics

- ✅ < 10 minute average approval time during business hours
- ✅ < 5% denial rate (most requests are legitimate)
- ✅ 100% of approvals have justification

---

## Decision 5: Deny Owner Assignment at Subscription Scope via Azure Policy

**Date:** 2026-03-02
**Decision Maker:** Security Team Lead + Platform Team Lead
**Status:** ✅ Approved and Implemented

### Context

Even with group-based RBAC and PIM, users with sufficient permissions could still create Owner role assignments at subscription scope, bypassing the PIM model.

### Decision

**Implement Azure Policy to deny Owner role assignments at subscription scope. Owner assignments only allowed at Management Group level (where PIM is enforced).**

### Rationale

1. **Preventive control:** Blocks attempts to bypass PIM by assigning at subscription level
2. **Enforcement:** Policy automatically denies - doesn't rely on manual review
3. **Compliance:** Forces all Owner assignments through Management Group (where PIM is configured)
4. **Audit-able:** Policy violations are logged

### Trade-offs

**Cons:**
- Less flexible - cannot make exceptions at subscription level (must use exemptions)
- Requires policy exemption process for legitimate edge cases
- Could block emergency access (mitigated by break-glass account)

**Pros:**
- Strong technical control against privilege escalation
- Enforces governance model automatically
- Clear signal to users about the proper access model

### Alternatives Considered

1. **Audit-only policy (no deny)**
   - Rejected: Doesn't prevent the action, only detects it after the fact

2. **Manual review process**
   - Rejected: Too slow, allows window for privilege escalation

3. **Role assignment approval workflow**
   - Rejected: Not natively supported in Azure RBAC

### Implementation Notes

- Policy deployed via Terraform (`azurerm_policy_definition` + `azurerm_management_group_policy_assignment`)
- Assigned at LandingZones MG scope
- Effect parameterized (can be set to Audit for testing, then Deny for enforcement)
- Current setting: **Deny**

### Policy Logic

```
IF role_assignment.role == "Owner"
   AND role_assignment.scope starts with "/subscriptions/"
THEN Deny
```

### Exemption Process

1. Requester submits ticket with business justification
2. Security Team + Platform Team review
3. If approved, create policy exemption in Terraform
4. Exemption expires after 90 days (must be renewed)

### Success Metrics

- ✅ 0 Owner assignments at subscription scope (all at MG level)
- ✅ < 5 policy exemptions created
- ✅ All exemptions documented and justified

---

## Decision 6: Application Team Contributor Access at Resource Group Level Only

**Date:** 2026-03-01
**Decision Maker:** Platform Team Lead
**Status:** ✅ Approved and Implemented

### Context

Application teams need Contributor access to deploy their applications, but granting Contributor at subscription level provides too much access.

### Decision

**Application teams receive Contributor role only at individual Resource Group level, not at subscription or Management Group level.**

### Rationale

1. **Blast radius reduction:** If application team makes mistake, only affects their resource group
2. **Multi-tenancy:** Multiple app teams can operate independently in same subscription
3. **No PIM needed:** Resource Group-scoped Contributor is low-risk enough for active assignment
4. **Prevents interference:** App teams cannot modify other teams' resources
5. **Namespace isolation:** Each app team has their own resource groups

### Trade-offs

**Cons:**
- More role assignments to manage (one per RG per team)
- App teams cannot create resource groups (must request from platform team)
- Slightly more complex initial setup

**Pros:**
- Strong isolation between application teams
- Clear ownership boundaries
- Lower risk (active assignments acceptable)
- Aligns with Azure landing zone guidance

### Alternatives Considered

1. **Contributor at subscription level with Azure Policy restrictions**
   - Rejected: Policy can be complex and may not cover all scenarios

2. **Custom role at subscription level (limited actions)**
   - Rejected: Still allows creating resources anywhere in subscription

3. **Separate subscriptions per app team**
   - Rejected: Too many subscriptions, management overhead, cost tracking complexity

### Implementation Notes

- Platform team creates resource groups with naming convention: `rg-{appname}-{env}`
- Contributor role assigned to `AZ-ROL-AppTeam-Contributor-Prod/NonProd` per RG
- Reader role at Management Group level for visibility
- Resource Groups include required tags (Environment, CostCenter, Owner)

### Success Metrics

- ✅ App teams can deploy to their RGs
- ✅ 0 incidents of one app team affecting another
- ✅ Resource group creation follows naming convention

---

## Decision 7: Security Reader Custom Role with Key Vault DataActions

**Date:** 2026-03-02
**Decision Maker:** Security Team Lead + Compliance Manager
**Status:** ✅ Approved and Implemented

### Context

Security team needs to audit Key Vault secrets for compliance (e.g., checking for secrets that should be rotated), but built-in Security Reader role doesn't include Key Vault secret read permissions.

### Decision

**Create custom role CR-SecurityReader-Enterprise with Key Vault secret read DataAction. Assign at subscription level (not MG level due to DataActions limitation).**

### Rationale

1. **Compliance requirement:** Security must be able to audit all secrets for compliance
2. **Read-only:** Security team doesn't need to modify secrets, only read for audits
3. **Least privilege:** Custom role includes only read permissions
4. **Audit trail:** All secret reads are logged in Key Vault audit logs

### Trade-offs

**Cons:**
- Security team can read all secrets (high-privilege data access)
- Custom role with DataActions cannot be assigned at Management Group level (Azure limitation)
- Must assign at each subscription individually

**Pros:**
- Enables security compliance audits
- Read-only (cannot modify secrets)
- All access logged
- Prevents need for Security team to have Contributor/Owner

### Alternatives Considered

1. **Grant Security team Contributor access when audits needed**
   - Rejected: Too much privilege, can modify resources

2. **Use Azure Key Vault RBAC (not access policies)**
   - Considered: Future enhancement, requires migrating all Key Vaults

3. **Export secrets to secure storage for security team review**
   - Rejected: Creates duplicate of sensitive data

4. **Built-in Key Vault Reader role**
   - Rejected: Doesn't include secret read DataAction

### Implementation Notes

- Custom role assigned at subscription level (not MG due to DataActions limitation)
- Role includes both control plane (Actions) and data plane (DataActions) permissions
- Security team members added to `AZ-ROL-Security-Reader` group
- All Key Vault access logged to Log Analytics

### Key Permissions

```
Actions:
✅ */read (all control plane reads)
✅ Microsoft.Authorization/*/read
✅ Microsoft.PolicyInsights/*/read
✅ Microsoft.Security/*/read

DataActions:
✅ Microsoft.KeyVault/vaults/secrets/getSecret/action
✅ Microsoft.KeyVault/vaults/certificates/read
```

### Security Controls

1. All secret reads logged to Log Analytics
2. Monthly review of security team Key Vault access
3. Conditional Access requires MFA for security team members
4. Alert on unusual patterns (e.g., bulk secret reads)

### Success Metrics

- ✅ Security team can audit Key Vault secrets
- ✅ All secret reads logged
- ✅ 0 incidents of secret misuse

---

## Decision 8: Terraform-Managed Role Assignments with CI/CD Approval Gate

**Date:** 2026-03-03
**Decision Maker:** Platform Team Lead + Security Team Lead
**Status:** ✅ Approved and Implemented

### Context

Role assignments are highly sensitive changes. Manual changes via Azure Portal are not version-controlled and lack approval workflow.

### Decision

**All role assignments must be managed via Terraform with CI/CD pipeline approval gate. No manual role assignments allowed (except emergency break-glass scenarios).**

### Rationale

1. **Version control:** All changes tracked in Git with commit history
2. **Code review:** Pull requests enable peer review before changes
3. **Approval workflow:** Pipeline approval gate requires Security + Platform team approval
4. **Audit trail:** Git commits + pipeline logs = complete audit trail
5. **Rollback capability:** Can revert to previous Terraform state if needed
6. **Consistency:** Infrastructure as Code ensures reproducibility
7. **Change visibility:** RBAC changes highlighted in pipeline output

### Trade-offs

**Cons:**
- Slower than manual changes in Portal (approval required)
- Requires Terraform knowledge to make changes
- Pipeline dependency (if pipeline is down, cannot make changes)
- Break-glass account needed for emergency access

**Pros:**
- Complete audit trail and change history
- Approval workflow prevents unauthorized changes
- Peer review reduces mistakes
- Can preview changes (terraform plan) before applying
- Documentation as code (role assignments self-documented)

### Alternatives Considered

1. **Manual changes in Portal with documentation**
   - Rejected: Documentation inevitably becomes outdated, no approval workflow

2. **ARM templates instead of Terraform**
   - Rejected: Terraform provides better state management and readability

3. **Azure Blueprints**
   - Rejected: Less flexible than Terraform, Microsoft is de-emphasizing Blueprints

4. **Terraform Cloud with Sentinel policies**
   - Considered: May implement in future for policy-as-code

### Implementation Notes

- Azure DevOps pipeline with 4 stages: Validate → Plan → Approve → Apply
- Approval gate requires min 2 approvers (Security + Platform representation)
- Pipeline includes script to parse and highlight RBAC changes
- State stored in Azure Storage with versioning enabled
- State lock prevents concurrent changes

### Pipeline Approval Requirements

- Minimum 2 approvers
- At least 1 approver from Security Team
- At least 1 approver from Platform Team
- Timeout: 7 days (auto-reject after)
- Rejections require justification

### Emergency Process

1. If pipeline is unavailable AND emergency change needed:
2. Use break-glass account to make manual change
3. Document change in incident ticket
4. Update Terraform code to match manual change within 24 hours
5. Run terraform plan to verify state matches reality

### Success Metrics

- ✅ 100% of role assignments managed via Terraform
- ✅ < 1% emergency manual changes
- ✅ All changes have Git commit + pipeline approval
- ✅ Average approval time < 4 hours during business hours

---

## Decision 9: PIM Eligibility Duration (180 days for Platform, 90 days for Consultants)

**Date:** 2026-03-03
**Decision Maker:** Platform Team Lead + HR
**Status:** ✅ Approved and Implemented

### Context

PIM eligible assignments can expire after a set duration. Need to determine appropriate eligibility duration for different roles.

### Decision

**Platform teams: 180-day eligibility (6 months) with automatic renewal via Terraform. Consultants: 90-day eligibility (engagement duration) with manual review before renewal.**

### Rationale

1. **Platform teams:** 180 days reduces renewal overhead while still requiring periodic review
2. **Automatic renewal:** Terraform re-creates eligible assignments on each apply (effectively auto-renewal)
3. **Consultants:** 90 days matches typical engagement length; manual review ensures engagement is still active
4. **Compliance:** Periodic eligibility review (every 6 months for employees) satisfies compliance requirements

### Trade-offs

**Cons:**
- Terraform auto-renewal might extend access longer than needed
- 180 days is relatively long (some organizations prefer 90 days)

**Pros:**
- Reduces administrative overhead (not re-certifying monthly)
- Terraform ensures eligibility doesn't accidentally expire
- Consultant duration matches business engagement cycle

### Alternatives Considered

1. **Permanent eligibility (never expires)**
   - Rejected: Doesn't force periodic access review

2. **90 days for everyone**
   - Rejected: Too frequent renewal for full-time employees

3. **Manual renewal for all**
   - Rejected: High administrative overhead, risk of accidental expiration

4. **365 days (1 year)**
   - Rejected: Too long between access reviews

### Implementation Notes

- Eligibility duration set in `azurerm_pim_eligible_role_assignment` resource
- Platform teams: `duration_hours = 4320` (180 days)
- Consultants: `duration_hours = 2160` (90 days)
- Terraform apply (run monthly) automatically renews expiring assignments
- Manual review before renewing consultant eligibility

### Success Metrics

- ✅ 0 accidental eligibility expirations
- ✅ Consultant eligibility reviewed before renewal
- ✅ Access reviews completed within eligibility window

---

## Decision 10: Break-Glass Account Storage Location

**Date:** 2026-03-01
**Decision Maker:** Security Team Lead + CISO
**Status:** ✅ Approved and Implemented

### Context

Break-glass account credentials must be accessible during emergencies but extremely secure. Location of credential storage is critical decision.

### Decision

**Break-glass account credentials stored in physical safe, NOT in Azure Key Vault or any cloud service.**

### Rationale

1. **Independence:** If Azure is completely unavailable, credentials must be accessible
2. **Defense in depth:** Credentials not stored in the environment they provide access to
3. **Attack resistance:** Physical safe cannot be compromised via cyber attack
4. **Compliance:** Many frameworks require offline break-glass credential storage

### Trade-offs

**Cons:**
- Physical safe must be accessible (office location)
- Requires physical security controls (safe access logging)
- Cannot rotate credentials automatically
- Slower to access during emergency (must retrieve from safe)

**Pros:**
- Completely independent of Azure infrastructure
- Cannot be compromised via cloud attack
- Physical access control (only authorized personnel)
- Aligns with industry best practices

### Alternatives Considered

1. **Azure Key Vault**
   - Rejected: If Azure/Key Vault is unavailable, break-glass is inaccessible

2. **Password manager (cloud-based)**
   - Rejected: Same issue - dependent on external service availability

3. **Printed and stored in executive's desk**
   - Rejected: Insufficient physical security

4. **Encrypted file on shared drive**
   - Rejected: Still dependent on network/IT infrastructure

### Implementation Notes

- Credentials stored in physical safe in security office
- Safe access restricted to: CISO, Security Manager, IT Director
- Safe access logged manually (log book)
- Credentials tested quarterly (break-glass drill)
- Alert configured for any use of break-glass account
- Account excluded from Conditional Access policies
- Account password manually rotated annually
- Backup copy in bank safety deposit box (extreme redundancy)

### Success Metrics

- ✅ Quarterly test successful (can retrieve and use credentials)
- ✅ 0 unauthorized access to safe
- ✅ < 2 actual uses per year (break-glass is truly rare)

---

## Summary of Key Decisions

| Decision | Impact | Risk Level | Implementation Status |
|----------|--------|------------|----------------------|
| No permanent Owner assignments | High | Medium | ✅ Implemented |
| Group-based RBAC only | High | Low | ✅ Implemented |
| Custom roles for CI/CD | Medium | Low | ✅ Implemented |
| PIM approval for Owner | Medium | Low | ✅ Implemented |
| Policy deny Owner at subscription | High | Low | ✅ Implemented |
| App team RG-scoped access | Medium | Low | ✅ Implemented |
| Security Reader with KV DataActions | Medium | Medium | ✅ Implemented |
| Terraform-managed assignments | High | Medium | ✅ Implemented |
| PIM eligibility duration (180d/90d) | Low | Low | ✅ Implemented |
| Break-glass physical storage | High | Low | ✅ Implemented |

---

## Future Decisions to Consider

1. **Azure AD Privileged Access Groups:** Potential future enhancement for group-level PIM
2. **Conditional Access integration:** Require specific locations for PIM activations
3. **PIM for Entra ID roles:** Currently only PIM for Azure resources; consider Entra ID role PIM
4. **Automated access reviews:** Use Entra ID Access Reviews for periodic certification
5. **JIT VM access:** Integrate Azure Defender JIT with PIM model
6. **Terraform Cloud/Sentinel:** Policy-as-code for Terraform changes
7. **Azure Lighthouse:** Multi-tenant management with customer approval

---

## Change Log

| Date | Decision | Change Description |
|------|----------|-------------------|
| 2026-03-01 | All | Initial decision log created |
| 2026-03-03 | Decision 8 | Updated pipeline approval requirements |

---

**Document Owner:** Security Team Lead + Platform Team Lead
**Review Frequency:** Quarterly
**Last Reviewed:** 2026-03-03
**Next Review Due:** 2026-06-03
**Version:** 1.0
