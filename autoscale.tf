# Terraform manifest to create a cluster of 6 web servers with high availability
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
  name     = "${var.rscname}-rg"
  location = var.location
}

#Create virtual network
resource "azurerm_virtual_network" "stan-vn" {
  name                = "${var.rscname}-vnet"
  resource_group_name = azurerm_resource_group.rgstan.name
  location            = azurerm_resource_group.rgstan.location
  address_space       = ["10.0.0.0/16"]

}

#Create Subnet
resource "azurerm_subnet" "stan-sbnet" {
  name                 = "${var.rscname}-sbnet"
  resource_group_name  = azurerm_resource_group.rgstan.name
  virtual_network_name = azurerm_virtual_network.stan-vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "tls_private_key" "autoscale-ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#create VM scale sets
resource "azurerm_linux_virtual_machine_scale_set" "autoscale" {
  name                = "${var.rscname}-vmss"
  resource_group_name = azurerm_resource_group.rgstan.name
  location            = azurerm_resource_group.rgstan.location
  sku                 = "Standard_B2s"
  instances           = 3
  admin_username      = "swaydevstan"

  admin_ssh_key {
    username   = "swaydevstan"
    public_key = tls_private_key.autoscale-ssh-key.public_key_openssh
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "sample-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.stan-sbnet.id
    }
  }
}

#create scaling rules
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-config"
  resource_group_name = azurerm_resource_group.rgstan.name
  location            = azurerm_resource_group.rgstan.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.autoscale.id

  profile {
    name = "AutoScale"

    capacity {
      default = 3
      minimum = 3
      maximum = 6
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.autoscale.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.autoscale.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}