# Pipeline Setup Checklist

Use this checklist to track your pipeline setup progress. Check off items as you complete them.

## Phase 1: Prerequisites

- [ ] Azure subscription with appropriate permissions
- [ ] Azure AD Premium P2 license available
- [ ] Azure DevOps organization created
- [ ] Azure DevOps project created
- [ ] Repository cloned locally

**Tools Installed:**
- [ ] Azure CLI (>= 2.50.x) - `az --version`
- [ ] Terraform (>= 1.5.7) - `terraform version`
- [ ] Python 3.x - `python3 --version`
- [ ] Git - `git --version`

**Azure CLI Authentication:**
- [ ] Logged in to Azure CLI - `az login`
- [ ] Correct subscription selected - `az account show`

---

## Phase 2: Terraform Backend

- [ ] Run backend setup script: `./pipeline/scripts/setup-terraform-backend.sh`
- [ ] Verify resource group created: `rg-terraform`
- [ ] Verify storage account created: `sttfstateta`
- [ ] Verify container created: `rbac-governance`
- [ ] Verify versioning enabled on storage account
- [ ] Verify soft delete enabled on storage account

**Backend Details (record for reference):**
```
Resource Group:    _________________________
Storage Account:   _________________________
Container:         _________________________
Location:          _________________________
Subscription ID:   _________________________
```

---

## Phase 3: Azure DevOps - Service Connection

- [ ] Navigate to Project Settings → Service connections
- [ ] Create new Azure Resource Manager connection
- [ ] Selected: Service Principal (automatic)
- [ ] Subscription selected
- [ ] Service connection named: `AzureRBACServiceConnection` (or custom name)
- [ ] Service connection saved successfully

**Service Connection Details:**
```
Connection Name:        _________________________
Service Principal ID:   _________________________
App ID:                 _________________________
Tenant ID:              _________________________
```

---

## Phase 4: Azure DevOps - Variable Group

- [ ] Navigate to Pipelines → Library
- [ ] Create new variable group
- [ ] Variable group named: `terraform-variables`
- [ ] Added variable: `AZURE_SERVICE_CONNECTION`
- [ ] Added variable: `TF_STATE_RG`
- [ ] Added variable: `TF_STATE_SA`
- [ ] Added variable: `TF_STATE_CONTAINER`
- [ ] Added variable: `SECURITY_TEAM_EMAIL`
- [ ] Added variable: `PLATFORM_TEAM_EMAIL`
- [ ] Variable group saved

**Variable Values:**
```
AZURE_SERVICE_CONNECTION: _________________________
TF_STATE_RG:              rg-terraform
TF_STATE_SA:              sttfstateta
TF_STATE_CONTAINER:       rbac-governance
SECURITY_TEAM_EMAIL:      _________________________
PLATFORM_TEAM_EMAIL:      _________________________
```

---

## Phase 5: Service Principal Permissions

### Storage Account Access
- [ ] Get service principal ID from service connection
- [ ] Grant "Storage Blob Data Contributor" role on storage account
  ```bash
  az role assignment create \
    --assignee <SP_ID> \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/<SUB_ID>/resourceGroups/rg-terraform/providers/Microsoft.Storage/storageAccounts/sttfstateta"
  ```
- [ ] Verify role assignment: `az role assignment list --assignee <SP_ID>`

### Azure RBAC Management
- [ ] Determine appropriate scope (Tenant Root or Management Group)
- [ ] Grant "Owner" role at appropriate scope
  ```bash
  az role assignment create \
    --assignee <SP_ID> \
    --role "Owner" \
    --scope "/providers/Microsoft.Management/managementGroups/<MG_ID>"
  ```
- [ ] Verify role assignment

### Microsoft Graph API Permissions
- [ ] Get App ID from service principal
- [ ] Add Group.ReadWrite.All permission (API permission)
- [ ] Add RoleManagement.ReadWrite.Directory permission (API permission)
  ```bash
  az ad app permission add --id <APP_ID> \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions \
      62a82d76-70ea-41e2-9197-370581804d09=Role \
      9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8=Role
  ```
- [ ] Grant admin consent (REQUIRED for Application/Role permissions)
  ```bash
  az ad app permission admin-consent --id <APP_ID>
  ```
- [ ] Wait 5-10 minutes for permissions to propagate
- [ ] Verify permissions granted in Azure Portal (should show green check marks)
  - Navigate to: Entra ID → App registrations → Your App → API permissions
  - Both permissions should show "Granted for [Your Tenant]"

---

## Phase 6: Terraform Initialization

Initialize each Terraform module:

- [ ] Initialize management-groups: `cd management-groups && terraform init`
- [ ] Initialize rbac: `cd rbac && terraform init`
- [ ] Initialize custom-roles: `cd custom-roles && terraform init`
- [ ] Initialize policies: `cd policies && terraform init`

**Validation:**
- [ ] All modules show "Terraform has been successfully initialized"
- [ ] No error messages
- [ ] `.terraform` directory created in each module
- [ ] Lock file created: `.terraform.lock.hcl`

---

## Phase 7: Azure DevOps - Pipeline Creation

- [ ] Navigate to Pipelines → New pipeline
- [ ] Select: Azure Repos Git
- [ ] Select your repository
- [ ] Choose: Existing Azure Pipelines YAML file
- [ ] Path: `/pipeline/azure-pipelines.yml`
- [ ] Click "Save" (don't run yet)

**Optional: Create Production Environment**
- [ ] Navigate to Pipelines → Environments
- [ ] Create environment: `production`
- [ ] Add approvers (optional additional approval)
- [ ] Configure checks/gates (optional)

---

## Phase 8: Validation

Run the validation script to verify setup:

- [ ] Run: `./pipeline/scripts/validate-setup.sh`
- [ ] All checks pass (green checkmarks)
- [ ] No critical errors (red X marks)
- [ ] Address any warnings

**Validation Results:**
```
Checks Passed:  _____
Checks Failed:  _____
Warnings:       _____
```

---

## Phase 9: First Pipeline Run (Dry Run)

- [ ] Create a small test change (e.g., update a comment in a .tf file)
- [ ] Commit and push to main branch
- [ ] Pipeline triggers automatically
- [ ] Validate stage completes successfully
- [ ] Plan stage completes successfully
- [ ] Review Terraform plans in artifacts
- [ ] Review RBAC change summary
- [ ] Approve stage appears (don't approve yet)
- [ ] Review approval checklist
- [ ] Cancel pipeline run (first dry run)

---

## Phase 10: Production Deployment

After successful dry run:

- [ ] Make desired infrastructure changes
- [ ] Commit and push to main branch
- [ ] Pipeline triggers
- [ ] Validate stage passes
- [ ] Plan stage passes
- [ ] Download and review all plan artifacts
- [ ] Review RBAC change summary artifact
- [ ] Verify changes match change ticket
- [ ] No unauthorized privilege escalations detected
- [ ] Approve in Approve stage
- [ ] Apply stage executes successfully
- [ ] All modules deployed successfully
- [ ] Verify changes in Azure Portal

---

## Phase 11: Post-Deployment Verification

- [ ] Verify Management Groups in Azure Portal
- [ ] Verify Entra ID groups created
- [ ] Verify custom roles deployed
- [ ] Verify role assignments correct
- [ ] Verify policies deployed
- [ ] Test PIM activation workflow
- [ ] Review Azure Activity Log
- [ ] Check Azure Policy compliance
- [ ] Verify no unexpected changes

---

## Phase 12: Documentation & Handoff

- [ ] Document actual service principal ID
- [ ] Document actual subscription IDs used
- [ ] Document any deviations from plan
- [ ] Update team documentation
- [ ] Train team on PIM activation
- [ ] Train team on pipeline approval process
- [ ] Create runbook for common operations
- [ ] Schedule regular access reviews

---

## Troubleshooting Checklist

If you encounter issues, verify:

- [ ] Service principal has correct permissions
- [ ] Variable group variables are correct
- [ ] Terraform backend is accessible
- [ ] No state lock conflicts
- [ ] Network connectivity to Azure
- [ ] Azure CLI token not expired
- [ ] Service connection not expired

**Common Commands:**
```bash
# Re-authenticate Azure CLI
az login

# Check current subscription
az account show

# Verify backend access
az storage container list --account-name sttfstateta

# Check Terraform state
cd <module> && terraform state list

# Force unlock (if needed)
terraform force-unlock <LOCK_ID>

# Re-initialize Terraform
terraform init -reconfigure
```

---

## Completion

- [ ] All phases completed successfully
- [ ] Pipeline running in production
- [ ] Team trained
- [ ] Documentation updated
- [ ] Monitoring in place

**Completed By:** _________________________
**Date:** _________________________
**Sign-off:** _________________________

---


**Setup Status:** ☐ Not Started / ☐ In Progress / ☐ Complete

**Last Updated:** _________________________
