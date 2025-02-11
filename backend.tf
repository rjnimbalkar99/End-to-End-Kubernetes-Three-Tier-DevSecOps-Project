terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend"
    storage_account_name = "terraformbackendprojects"
    container_name       = "tfstate"
    key                 = "terraform.tfstate"
  }
}