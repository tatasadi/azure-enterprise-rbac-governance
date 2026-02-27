# Pipeline Quick Start Guide

## 🚀 5-Minute Setup

### Prerequisites Checklist
- [ ] Azure subscription access
- [ ] Azure DevOps organization
- [ ] Azure CLI installed
- [ ] Terraform installed (>= 1.5.7)

---

## Step 1: Create Backend (2 minutes)

```bash
cd pipeline/scripts
./setup-terraform-backend.sh
```

**Outputs to save:**
- Resource Group: `rg-terraform`
- Storage Account: `sttfstateta`
- Container: `rbac-governance`

---

## Step 2: Azure DevOps Setup (2 minutes)

### Create Service Connection
1. Go to **Project Settings** → **Service connections**
2. Click **New service connection** → **Azure Resource Manager**
3. Select **Service Principal (automatic)**
4. Choose subscription → Name: `AzureRBACServiceConnection`
5. Click **Save**

### Create Variable Group
1. Go to **Pipelines** → **Library** → **+ Variable group**
2. Name: `terraform-variables`
3. Add these variables:

```
AZURE_SERVICE_CONNECTION = AzureRBACServiceConnection
TF_STATE_RG = rg-terraform
TF_STATE_SA = sttfstateta
TF_STATE_CONTAINER = rbac-governance
SECURITY_TEAM_EMAIL = your-security-team@company.com
PLATFORM_TEAM_EMAIL = your-platform-team@company.com
```

4. Click **Save**

---

## Step 3: Grant Permissions (1 minute)

### Get Service Principal ID
```bash
# From service connection, copy the Service Principal ID
# OR find it via:
az ad sp list --display-name "AzureRBACServiceConnection" --query "[0].id" -o tsv
```

### Storage Access
```bash
SP_ID="<YOUR_SERVICE_PRINCIPAL_ID>"
SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"

az role assignment create \
  --assignee $SP_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-terraform/providers/Microsoft.Storage/storageAccounts/sttfstateta"
```

### Azure RBAC Access
```bash
# Get your tenant root management group ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Grant Owner at tenant root (or specific management group)
az role assignment create \
  --assignee $SP_ID \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/$TENANT_ID"
```

### Entra ID Permissions
```bash
# Get the App ID from service principal
APP_ID=$(az ad sp show --id $SP_ID --query appId -o tsv)
echo "App ID: $APP_ID"

# Add Microsoft Graph permissions (Group.ReadWrite.All + RoleManagement.ReadWrite.Directory)
az ad app permission add \
  --id $APP_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions \
    62a82d76-70ea-41e2-9197-370581804d09=Role \
    9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8=Role

# Grant admin consent (REQUIRED - must be Global Admin or Privileged Role Admin)
az ad app permission admin-consent --id $APP_ID

# Verify permissions granted (wait 1-2 minutes)
az ad app permission list --id $APP_ID -o table
```

**Note:** Admin consent is required for Application permissions. Wait 5-10 minutes for full propagation.

---

## Step 4: Create Pipeline (< 1 minute)

1. Go to **Pipelines** → **New pipeline**
2. Select **Azure Repos Git**
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Path: `/pipeline/azure-pipelines.yml`
6. Click **Save** (don't run yet)

---

## Step 5: Initialize Terraform (1 minute)

```bash
# Run from repository root
for dir in management-groups rbac custom-roles policies; do
  echo "Initializing $dir..."
  cd $dir
  terraform init
  cd ..
done
```

---

## ✅ Ready to Deploy!

### First Run

1. Make a change to any `.tf` file
2. Commit and push to `main` branch
3. Pipeline automatically triggers
4. Review plan in **Plan** stage
5. Check RBAC changes artifact
6. Approve in **Approve** stage
7. Changes apply automatically

---

## 🎯 Quick Commands Reference

### Check Pipeline Status
```bash
# Via Azure DevOps CLI (optional)
az pipelines runs list --project <PROJECT> --pipeline-ids <PIPELINE_ID>
```

### Manual Terraform Plan
```bash
cd rbac
terraform plan
```

### View State
```bash
cd rbac
terraform state list
terraform state show <resource_address>
```

### Download Plan from Pipeline
1. Go to pipeline run
2. Click **Artifacts**
3. Download `rbac-terraform-plan`

---

## 🔧 Common First-Time Issues

### Issue: "Backend initialization required"
**Fix:**
```bash
cd <module>
terraform init -reconfigure
```

### Issue: "Permission denied"
**Fix:** Wait 5-10 minutes after granting Graph permissions for propagation

### Issue: "State lock timeout"
**Fix:**
```bash
# Check and break stuck leases in Azure Portal
# Storage Account → Containers → rbac-governance → <module>.tfstate → Break lease
```

---

## 📊 Verify Setup

Run this checklist to verify everything is ready:

```bash
# 1. Check Azure CLI is authenticated
az account show

# 2. Check Terraform version
terraform version  # Should be >= 1.5.7

# 3. Check backend exists
az storage account show -n sttfstateta -g rg-terraform

# 4. Check service principal exists
az ad sp list --display-name "AzureRBACServiceConnection"

# 5. Check role assignments
az role assignment list --assignee <SP_ID> --all

# 6. Test Terraform init
cd management-groups && terraform init
```

All checks passed? **You're ready to run the pipeline!** 🎉

---

## 📞 Need Help?

- **Documentation:** See [README.md](README.md) for detailed documentation
- **Troubleshooting:** Check the Troubleshooting section in README
- **Issues:** Open an issue in the repository

---

**Next Steps:** See [README.md](README.md) for detailed pipeline documentation and best practices.
