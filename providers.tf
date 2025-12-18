terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateazmig"
    container_name       = "tfstate"
    key                  = "todoappauto.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "e035c6a6-7703-4c41-8736-d7668db3a49b"
}

# -----------------------------
# Existing Storage Account (Data Source)
# -----------------------------
data "azurerm_storage_account" "tfstate" {
  name                = "tfstateazmig"
  resource_group_name = "tfstate-rg"
}