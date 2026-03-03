# Azure Enterprise RBAC & PIM Governance Accelerator

Enterprise-grade Azure access governance using RBAC, Privileged Identity Management (PIM), and policy-driven guardrails. Infrastructure as Code implementation for mid-sized enterprises.

## 🎯 Project Overview

This repository implements a secure, scalable Azure governance model featuring:

- **Management Group Hierarchy** - Organized structure for Platform and Landing Zones
- **Group-Based RBAC** - Zero direct user assignments, all via Entra ID groups
- **Privileged Identity Management** - Just-in-time access for Owner/Contributor roles
- **Custom Roles** - Least-privilege roles for deployment and security
- **Azure Policy** - Automated enforcement of governance rules
- **Infrastructure as Code** - Fully managed via Terraform

## 📋 Prerequisites

### Required Licenses & Access
- ✅ Azure AD Premium P2 (for PIM)
- ✅ Owner permissions at Tenant Root Management Group
- ✅ Global Administrator or Privileged Role Administrator

### Required Tools
```bash
terraform >= 1.5.0
az cli >= 2.50.0
git
```

### Azure Environment
- 4 Subscriptions (Platform-Connectivity, Platform-Identity, Workload-Prod, Workload-NonProd)
- Storage account for Terraform state
- Relatively clean tenant (or ability to create groups/policies)

## 🏗️ Architecture

### Management Group Hierarchy
```
Tenant Root
│
├── Platform
│   ├── Identity
│   └── Connectivity
│
└── LandingZones
    ├── Prod
    └── NonProd
```

### RBAC Model Principles
1. **No direct user assignments** - Only via Entra ID groups
2. **PIM for privileged roles** - Owner/Contributor eligible only
3. **Scoped assignments** - Resource Group level for app teams
4. **Custom roles** - Minimal privilege for deployment
5. **Policy enforcement** - Prevent privilege sprawl

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd azure-enterprise-rbac-governance
```

### 2. Update Backend Configuration

Edit the storage account name in each module's `providers.tf`:
```bash
# Update these files with your storage account name:
# - management-groups/providers.tf
# - rbac/providers.tf
# - custom-roles/providers.tf
# - policies/providers.tf

# Replace "sttfstateta" with your actual storage account name
```

### 3. Configure Variables

```bash
# Management Groups
cd management-groups
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription IDs

# RBAC
cd ../rbac
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your user object ID

# Custom Roles
cd ../custom-roles
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription IDs

# Policies
cd ../policies
cp terraform.tfvars.example terraform.tfvars
# Review policy effects (start with Audit)
```

### 4. Deploy in Order

#### Step 1: Management Groups
```bash
cd management-groups
terraform init
terraform plan
terraform apply
```

#### Step 2: Custom Roles
```bash
cd ../custom-roles
terraform init
terraform plan
terraform apply
```

#### Step 3: RBAC Groups & Assignments
```bash
cd ../rbac
terraform init
terraform plan
terraform apply
```

#### Step 4: Azure Policies
```bash
cd ../policies
terraform init
terraform plan
terraform apply
```

#### Step 5: PIM Configuration
PIM eligible assignments are automatically created by the RBAC module. Follow the guide in [pim/README.md](pim/README.md) to:
- Verify Terraform created the eligible assignments
- Configure role activation policies (duration, approval, MFA) in the Portal
- Set up approval workflows
- (Optional) Migrate any existing permanent assignments to eligible

## 📁 Repository Structure

```
.
├── management-groups/     # Management group hierarchy and subscription assignments
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── rbac/                  # Entra ID groups and role assignments
│   ├── main.tf
│   ├── providers.tf
│   ├── entra-groups.tf
│   ├── group-assignments.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── custom-roles/          # Custom RBAC role definitions
│   ├── main.tf
│   ├── providers.tf
│   ├── app-deployer.json
│   ├── security-reader.json
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── policies/              # Azure Policy definitions and assignments
│   ├── main.tf
│   ├── providers.tf
│   ├── deny-owner-assignments.json
│   ├── audit-privileged-roles.json
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── pim/                   # PIM configuration documentation
│   └── README.md          # PIM activation policy configuration guide
│
├── pipeline/              # Azure DevOps CI/CD pipeline
│   ├── azure-pipelines.yml
│   ├── scripts/
│   │   └── parse-rbac-changes.py
│   ├── README.md
│   ├── QUICK_START.md
│   └── SETUP_CHECKLIST.md
│
└── README.md             # This file
```

## 🔐 Security Features

### Entra ID Groups Created

| Group Name | Purpose | Assignment Type |
|------------|---------|-----------------|
| AZ-ROL-Platform-Owner-Eligible | Platform team Owner | ✅ PIM Eligible (2h activation, 180d duration) |
| AZ-ROL-Platform-Contributor-Eligible | Platform team Contributor | ✅ PIM Eligible (4h activation, 180d duration) |
| AZ-ROL-Consultant-Contributor-Temp | External consultants | ✅ PIM Eligible (2h activation, 90d duration) |
| AZ-ROL-AppTeam-Contributor-Prod | App teams Prod access | ❌ Active (RG-scoped) |
| AZ-ROL-AppTeam-Contributor-NonProd | App teams NonProd access | ❌ Active (RG-scoped) |
| AZ-ROL-AppTeam-Reader-Prod | App teams Prod read access | ❌ Active |
| AZ-ROL-AppTeam-Reader-NonProd | App teams NonProd read access | ❌ Active |
| AZ-ROL-Security-Reader | Security team reader | ❌ Active |
| AZ-ROL-Audit-Reader | Audit team reader | ❌ Active |
| AZ-ROL-Network-Contributor | Network team | ❌ Active |
| AZ-ROL-Identity-Contributor | Identity team | ❌ Active |
| AZ-ROL-DevOps-Deployer-Prod | CI/CD pipelines Prod | ❌ Active (Custom role) |
| AZ-ROL-DevOps-Deployer-NonProd | CI/CD pipelines NonProd | ❌ Active (Custom role) |

### Custom Roles Created

1. **CR-AppDeployer-ResourceGroup-Prod** - Deploy apps to Prod without Owner/delete permissions
2. **CR-AppDeployer-ResourceGroup-NonProd** - Deploy apps to NonProd without Owner/delete permissions
3. **CR-SecurityReader-Enterprise** - Read-only security access including Key Vault secrets and policies

### Azure Policies Deployed

1. **Deny Owner at Subscription Scope** - Forces use of PIM at MG level
2. **Audit Privileged Roles** - Tracks permanent privileged assignments
3. **Require Resource Group Tags** - Enforces tagging for governance

## 🔄 Workflow

### How to Activate Owner Role (PIM)

1. Navigate to **Entra ID → Privileged Identity Management**
2. Go to **My roles → Azure resources**
3. Find **Owner** role at Platform Management Group
4. Click **Activate**
5. Provide justification
6. Wait for approval (if required)
7. Access granted for 2 hours

### How to Deploy Changes via Terraform

```bash
# Make changes to .tf files
git checkout -b feature/add-new-group

# Plan changes
cd rbac
terraform plan

# Apply (requires approval in pipeline - Phase 2)
terraform apply

# Commit and push
git add .
git commit -m "Add new RBAC group for data team"
git push origin feature/add-new-group
```

## 📊 Compliance & Monitoring

### Daily Tasks
- Review PIM activation requests
- Approve/deny privileged access

### Weekly Tasks
- Review PIM activation logs
- Check Azure Policy compliance dashboard
- Verify no permanent Owner assignments

### Monthly Tasks
- Review Entra ID group memberships
- Audit role assignments
- Renew expiring PIM eligible assignments

### Quarterly Tasks
- Test break-glass account
- Review and update custom roles
- Assess PIM policy effectiveness

## 🚨 Emergency Access (Break-Glass)

**CRITICAL:** Set up break-glass account BEFORE implementing PIM!

1. Create emergency account: `breakglass@yourdomain.com`
2. Assign permanent Owner at Tenant Root
3. Store credentials in physical safe (NOT Azure Key Vault)
4. Exclude from Conditional Access
5. Set up alerting for any use
6. Test quarterly

## 📚 Documentation

### Core Documentation
- [README.md](README.md) - This file - project overview and quick start

### Operational Guides
- [pim/README.md](pim/README.md) - PIM configuration and activation policies
- [docs/runbook.md](docs/runbook.md) - Operational procedures and troubleshooting

### Architecture & Design
- [docs/architecture-diagram.md](docs/architecture-diagram.md) - Visual architecture diagrams and data flows
- [docs/role-matrix.md](docs/role-matrix.md) - Complete RBAC role assignment matrix
- [docs/security-decisions.md](docs/security-decisions.md) - Security decision log and rationale

### Pipeline Documentation
- [pipeline/README.md](pipeline/README.md) - CI/CD pipeline setup and usage
- [pipeline/QUICK_START.md](pipeline/QUICK_START.md) - Quick start guide for pipeline
- [pipeline/SETUP_CHECKLIST.md](pipeline/SETUP_CHECKLIST.md) - Pipeline setup checklist

## 🛠️ Troubleshooting

### "Access Denied" when activating PIM role
- Verify you're a member of the Entra ID group
- Check PIM eligibility hasn't expired
- Ensure MFA is configured
- Wait for approval if required

### Terraform state lock error
- Check if another pipeline is running
- Verify state storage account access
- Break lock manually if stale (with caution)

### Policy blocking legitimate deployment
- Review policy exemptions process
- Temporarily set effect to "Audit" mode
- Document exemption request

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes and test locally
3. Run `terraform plan` and review output
4. Create pull request with description
5. Wait for approval from security team
6. Pipeline will run `terraform apply` after approval

## 📖 References

- [Azure PIM Best Practices](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-deployment-plan)
- [Azure RBAC Best Practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices)
- [Management Group Design](https://learn.microsoft.com/en-us/azure/governance/management-groups/overview)
- [Azure Landing Zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

## 📝 License

This project is licensed under the MIT License.

## 🎓 Skills Demonstrated

- Azure Identity & Access Management
- Privileged Identity Management (PIM)
- Infrastructure as Code (Terraform)
- Azure Policy & Governance
- Security Hardening
- Enterprise Architecture
- DevOps & CI/CD

---

**Version:** 1.1
**Last Updated:** 2026-03-03
**Phase 7 Status:** ✅ Documentation Complete
