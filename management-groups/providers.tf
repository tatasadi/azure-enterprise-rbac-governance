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
    key                  = "management-groups.tfstate"
  }
}

provider "azurerm" {
  features {}
}
