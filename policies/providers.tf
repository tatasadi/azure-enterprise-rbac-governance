terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "sttfstateta"
    container_name       = "rbac-governance"
    key                  = "policies.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}

  # Disable Azure CLI authentication in CI/CD pipelines
  # The AzureCLI@2 task sets ARM_* environment variables
  # for Service Principal authentication
  use_cli = false
}
