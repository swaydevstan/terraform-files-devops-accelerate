# Terraform manifest to create a load balancer
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}

#uncomment to store state files in Azure storage
# backend "azurerm" {
#         resource_group_name  = "tfstate"
#         storage_account_name = "<storage_account_name>"
#         container_name       = "tfstate"
#         key                  = "terraform.tfstate"
# }

provider "azurerm" {
  features {}

}

resource "azurerm_resource_group" "rgstan" {
  name     = "${var.lbrsc}-rg"
  location = var.location
}

resource "azurerm_public_ip" "lb-ip" {
  name                = "${var.lbrsc}-ip"
  location            = azurerm_resource_group.rgstan.location
  resource_group_name = azurerm_resource_group.rgstan.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "loadbalancer" {
  name                = "${var.lbrsc}-lb"
  location            = azurerm_resource_group.rgstan.location
  resource_group_name = azurerm_resource_group.rgstan.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb-ip.id
  }
}