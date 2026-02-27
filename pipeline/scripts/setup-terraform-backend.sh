#!/bin/bash
#
# Terraform Backend Setup Script
#
# This script creates the Azure Storage Account and Container needed
# for Terraform remote state management with state locking.
#
# Prerequisites:
# - Azure CLI installed and authenticated (az login)
# - Appropriate permissions to create resources
#

set -e  # Exit on error

# Configuration
RESOURCE_GROUP_NAME="${TF_STATE_RG:-rg-terraform}"
LOCATION="${AZURE_LOCATION:-westeurope}"
STORAGE_ACCOUNT_NAME="${TF_STATE_SA:-sttfstateta}"
CONTAINER_NAME="${TF_STATE_CONTAINER:-rbac-governance}"
TAGS="Environment=Production Project=RBAC-Governance ManagedBy=Terraform"

echo "======================================================================="
echo "  Terraform Backend Setup for Azure RBAC & Governance"
echo "======================================================================="
echo ""
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Location: $LOCATION"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo ""
read -p "Continue with this configuration? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

echo ""
echo "Step 1: Creating Resource Group..."
echo "-----------------------------------"

if az group show --name "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo "✓ Resource Group '$RESOURCE_GROUP_NAME' already exists"
else
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags $TAGS
    echo "✓ Resource Group created"
fi

echo ""
echo "Step 2: Creating Storage Account..."
echo "------------------------------------"

if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo "✓ Storage Account '$STORAGE_ACCOUNT_NAME' already exists"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --encryption-services blob \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --tags $TAGS
    echo "✓ Storage Account created"
fi

echo ""
echo "Step 3: Enabling Versioning and Soft Delete..."
echo "-----------------------------------------------"

# Enable versioning for state file protection
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-versioning true \
    --enable-change-feed true

# Enable soft delete (7 days retention)
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-delete-retention true \
    --delete-retention-days 7

echo "✓ Versioning and Soft Delete enabled"

echo ""
echo "Step 4: Creating Storage Container..."
echo "--------------------------------------"

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$ACCOUNT_KEY" &>/dev/null; then
    echo "✓ Container '$CONTAINER_NAME' already exists"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$ACCOUNT_KEY" \
        --public-access off
    echo "✓ Container created"
fi

echo ""
echo "Step 5: Setting up RBAC for Service Principal (Optional)..."
echo "------------------------------------------------------------"
echo ""
echo "For Azure DevOps pipeline, grant the service principal:"
echo "  - 'Storage Blob Data Contributor' on the container"
echo ""
echo "Example command:"
echo "  az role assignment create \\"
echo "    --assignee <SERVICE_PRINCIPAL_ID> \\"
echo "    --role 'Storage Blob Data Contributor' \\"
echo "    --scope '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME'"
echo ""

echo "======================================================================="
echo "  ✓ Terraform Backend Setup Complete!"
echo "======================================================================="
echo ""
echo "Backend Configuration:"
echo ""
echo "  resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "  container_name       = \"$CONTAINER_NAME\""
echo ""
echo "This configuration is already present in all module providers.tf files."
echo ""
echo "Next Steps:"
echo "  1. Configure Azure DevOps service connection"
echo "  2. Set up pipeline variable group 'terraform-variables'"
echo "  3. Add these variables to the variable group:"
echo "     - AZURE_SERVICE_CONNECTION"
echo "     - TF_STATE_RG = $RESOURCE_GROUP_NAME"
echo "     - TF_STATE_SA = $STORAGE_ACCOUNT_NAME"
echo "     - TF_STATE_CONTAINER = $CONTAINER_NAME"
echo "     - SECURITY_TEAM_EMAIL"
echo "     - PLATFORM_TEAM_EMAIL"
echo "  4. Run: cd <module> && terraform init"
echo ""
echo "Security Features Enabled:"
echo "  ✓ Blob versioning (protection against accidental overwrites)"
echo "  ✓ Soft delete (7-day recovery window)"
echo "  ✓ TLS 1.2 minimum"
echo "  ✓ HTTPS only"
echo "  ✓ No public blob access"
echo "  ✓ Encryption at rest"
echo ""
