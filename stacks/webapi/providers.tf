terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }

  backend "azurerm" {} # values injected by -backend-config at CI time
}

provider "azurerm" {
  features {}
  use_oidc = true
}