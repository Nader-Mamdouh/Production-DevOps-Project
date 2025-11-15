
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"   # or latest 3.x stable
    }
  }
}
provider "azurerm" {
  features {}
}
