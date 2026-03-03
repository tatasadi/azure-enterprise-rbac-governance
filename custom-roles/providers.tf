terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "sttfstateta"
    container_name       = "rbac-governance"
    key                  = "custom-roles.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  use_cli = false
}
