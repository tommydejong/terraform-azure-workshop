terraform {
  backend "azurerm" {
    resource_group_name  = "bctf-workshop-rg"
    storage_account_name = "bcworkshoptfstates"
    container_name       = "tfstates"
    key                  = "tommy.terraform.tfstate"
  }
}