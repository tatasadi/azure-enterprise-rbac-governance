#!/bin/bash
#
# Pipeline Setup Validation Script
#
# This script validates that all prerequisites are in place for running
# the Azure RBAC & Governance pipeline.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Configuration
TF_STATE_RG="${TF_STATE_RG:-rg-terraform}"
TF_STATE_SA="${TF_STATE_SA:-sttfstateta}"
TF_STATE_CONTAINER="${TF_STATE_CONTAINER:-rbac-governance}"

echo "======================================================================="
echo "  Azure RBAC & Governance Pipeline - Setup Validation"
echo "======================================================================="
echo ""

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    echo "  Error: $2"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo "  Warning: $2"
    ((CHECKS_WARNING++))
}

section() {
    echo ""
    echo "-------------------------------------------------------------------"
    echo "$1"
    echo "-------------------------------------------------------------------"
}

# ============================================================================
# CHECK 1: Prerequisites - Tools
# ============================================================================
section "1. Checking Required Tools"

# Azure CLI
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --query '\"azure-cli\"' -o tsv)
    check_pass "Azure CLI installed (version $AZ_VERSION)"
else
    check_fail "Azure CLI not found" "Install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

# Terraform
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)

    # Check version >= 1.5.0
    REQUIRED_VERSION="1.5.0"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TF_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        check_pass "Terraform installed (version $TF_VERSION)"
    else
        check_warn "Terraform version $TF_VERSION found" "Version 1.5.0 or higher recommended"
    fi
else
    check_fail "Terraform not found" "Install from https://www.terraform.io/downloads"
fi

# Python 3
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    check_pass "Python 3 installed (version $PYTHON_VERSION)"
else
    check_fail "Python 3 not found" "Required for RBAC change parser script"
fi

# Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    check_pass "Git installed (version $GIT_VERSION)"
else
    check_fail "Git not found" "Install git"
fi

# ============================================================================
# CHECK 2: Azure Authentication
# ============================================================================
section "2. Checking Azure Authentication"

if az account show &> /dev/null; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    check_pass "Azure CLI authenticated"
    echo "  Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
    echo "  Tenant: $TENANT_ID"
else
    check_fail "Not authenticated to Azure" "Run 'az login'"
fi

# ============================================================================
# CHECK 3: Terraform Backend
# ============================================================================
section "3. Checking Terraform Backend Infrastructure"

# Resource Group
if az group show --name "$TF_STATE_RG" &> /dev/null; then
    check_pass "Resource group '$TF_STATE_RG' exists"
else
    check_fail "Resource group '$TF_STATE_RG' not found" "Run ./pipeline/scripts/setup-terraform-backend.sh"
fi

# Storage Account
if az storage account show --name "$TF_STATE_SA" --resource-group "$TF_STATE_RG" &> /dev/null; then
    check_pass "Storage account '$TF_STATE_SA' exists"

    # Check versioning
    VERSIONING=$(az storage account blob-service-properties show \
        --account-name "$TF_STATE_SA" \
        --resource-group "$TF_STATE_RG" \
        --query "isVersioningEnabled" -o tsv 2>/dev/null || echo "false")

    if [ "$VERSIONING" = "true" ]; then
        check_pass "Blob versioning enabled"
    else
        check_warn "Blob versioning not enabled" "Enable for state file protection"
    fi

    # Check soft delete
    SOFT_DELETE=$(az storage account blob-service-properties show \
        --account-name "$TF_STATE_SA" \
        --resource-group "$TF_STATE_RG" \
        --query "deleteRetentionPolicy.enabled" -o tsv 2>/dev/null || echo "false")

    if [ "$SOFT_DELETE" = "true" ]; then
        check_pass "Soft delete enabled"
    else
        check_warn "Soft delete not enabled" "Enable for state file recovery"
    fi
else
    check_fail "Storage account '$TF_STATE_SA' not found" "Run ./pipeline/scripts/setup-terraform-backend.sh"
fi

# Container
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$TF_STATE_RG" \
    --account-name "$TF_STATE_SA" \
    --query '[0].value' -o tsv 2>/dev/null || echo "")

if [ -n "$ACCOUNT_KEY" ]; then
    if az storage container show \
        --name "$TF_STATE_CONTAINER" \
        --account-name "$TF_STATE_SA" \
        --account-key "$ACCOUNT_KEY" &> /dev/null; then
        check_pass "Storage container '$TF_STATE_CONTAINER' exists"
    else
        check_fail "Storage container '$TF_STATE_CONTAINER' not found" "Run ./pipeline/scripts/setup-terraform-backend.sh"
    fi
fi

# ============================================================================
# CHECK 4: Terraform Initialization
# ============================================================================
section "4. Checking Terraform Module Initialization"

for module in management-groups rbac custom-roles policies; do
    if [ -d "$module" ]; then
        if [ -d "$module/.terraform" ]; then
            check_pass "Module '$module' is initialized"
        else
            check_warn "Module '$module' not initialized" "Run: cd $module && terraform init"
        fi
    else
        check_warn "Module directory '$module' not found" "Expected in repository"
    fi
done

# ============================================================================
# CHECK 5: Pipeline Files
# ============================================================================
section "5. Checking Pipeline Files"

# Pipeline YAML
if [ -f "pipeline/azure-pipelines.yml" ]; then
    check_pass "Pipeline YAML found"
else
    check_fail "Pipeline YAML not found" "Expected at pipeline/azure-pipelines.yml"
fi

# RBAC Parser Script
if [ -f "pipeline/scripts/parse-rbac-changes.py" ]; then
    if [ -x "pipeline/scripts/parse-rbac-changes.py" ]; then
        check_pass "RBAC parser script found and executable"
    else
        check_warn "RBAC parser script not executable" "Run: chmod +x pipeline/scripts/parse-rbac-changes.py"
    fi
else
    check_fail "RBAC parser script not found" "Expected at pipeline/scripts/parse-rbac-changes.py"
fi

# Backend setup script
if [ -f "pipeline/scripts/setup-terraform-backend.sh" ]; then
    if [ -x "pipeline/scripts/setup-terraform-backend.sh" ]; then
        check_pass "Backend setup script found and executable"
    else
        check_warn "Backend setup script not executable" "Run: chmod +x pipeline/scripts/setup-terraform-backend.sh"
    fi
else
    check_fail "Backend setup script not found" "Expected at pipeline/scripts/setup-terraform-backend.sh"
fi

# ============================================================================
# CHECK 6: Python Dependencies for RBAC Parser
# ============================================================================
section "6. Checking Python Dependencies"

if command -v python3 &> /dev/null; then
    # Test if script can run
    if python3 -c "import json, sys" &> /dev/null; then
        check_pass "Python dependencies available (json, sys)"
    else
        check_fail "Python dependencies missing" "Required modules not available"
    fi
fi

# ============================================================================
# CHECK 7: Git Repository
# ============================================================================
section "7. Checking Git Repository"

if [ -d ".git" ]; then
    check_pass "Git repository initialized"

    # Check remote
    if git remote -v | grep -q "origin"; then
        REMOTE_URL=$(git remote get-url origin)
        check_pass "Git remote configured"
        echo "  Remote: $REMOTE_URL"
    else
        check_warn "Git remote not configured" "Configure Azure Repos remote"
    fi

    # Check current branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        check_pass "On main/master branch"
    else
        check_warn "Not on main branch" "Current branch: $CURRENT_BRANCH"
    fi
else
    check_fail "Not a git repository" "Initialize git repository"
fi

# ============================================================================
# CHECK 8: Module Structure
# ============================================================================
section "8. Checking Terraform Module Structure"

EXPECTED_FILES=(
    "management-groups/main.tf"
    "management-groups/variables.tf"
    "management-groups/outputs.tf"
    "management-groups/providers.tf"
    "rbac/main.tf"
    "rbac/variables.tf"
    "rbac/outputs.tf"
    "rbac/providers.tf"
    "custom-roles/main.tf"
    "custom-roles/variables.tf"
    "custom-roles/outputs.tf"
    "custom-roles/providers.tf"
    "policies/main.tf"
    "policies/variables.tf"
    "policies/outputs.tf"
    "policies/providers.tf"
)

for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$file" ]; then
        ((CHECKS_PASSED++))
    else
        check_warn "Missing expected file: $file" "Module structure incomplete"
    fi
done

if [ ${#EXPECTED_FILES[@]} -eq $CHECKS_PASSED ]; then
    echo -e "${GREEN}✓${NC} All expected module files present"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "======================================================================="
echo "  Validation Summary"
echo "======================================================================="
echo ""
echo -e "Checks Passed:  ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Checks Failed:  ${RED}$CHECKS_FAILED${NC}"
echo -e "Warnings:       ${YELLOW}$CHECKS_WARNING${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Setup validation successful!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Create Azure DevOps service connection"
    echo "  2. Create variable group 'terraform-variables'"
    echo "  3. Grant service principal permissions"
    echo "  4. Create pipeline from azure-pipelines.yml"
    echo ""
    echo "See pipeline/QUICK_START.md for detailed instructions."
    exit 0
else
    echo -e "${RED}✗ Setup validation failed${NC}"
    echo ""
    echo "Please fix the errors above before proceeding."
    echo "See pipeline/README.md for troubleshooting."
    exit 1
fi
