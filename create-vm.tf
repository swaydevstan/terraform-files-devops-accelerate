# Terraform file to create a single Azure-VM instance

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

#Create resource group
resource "azurerm_resource_group" "rgstan" {
  name     = "${var.prefix}-rg"
  location = var.location
}

#Create virtual network
resource "azurerm_virtual_network" "stan-vn" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rgstan.name
  location            = azurerm_resource_group.rgstan.location
  address_space       = ["10.0.0.0/16"]

}

#Create Subnet
resource "azurerm_subnet" "stan-sbnet" {
  name                 = "${var.prefix}-sbnet"
  resource_group_name  = azurerm_resource_group.rgstan.name
  virtual_network_name = azurerm_virtual_network.stan-vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

#create public ip
resource "azurerm_public_ip" "stan-ip" {
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.rgstan.name
  location            = azurerm_resource_group.rgstan.location
  allocation_method   = "Dynamic"

}

#Create the NIC
resource "azurerm_network_interface" "stan-nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rgstan.location
  resource_group_name = azurerm_resource_group.rgstan.name

  ip_configuration {
    name                          = "Internal"
    subnet_id                     = azurerm_subnet.stan-sbnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.stan-ip.id
  }

}

#create security group
resource "azurerm_network_security_group" "stan-sg" {
  name                = "${var.prefix}-security-group"
  location            = azurerm_resource_group.rgstan.location
  resource_group_name = azurerm_resource_group.rgstan.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-http"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#apply security group rule to subnet
resource "azurerm_subnet_network_security_group_association" "stan-sga" {
  subnet_id                 = azurerm_subnet.stan-sbnet.id
  network_security_group_id = azurerm_network_security_group.stan-sg.id
}

# Create an SSH key
resource "tls_private_key" "swaydevstan-ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Creare linux virtual machine (Ubuntu flavor)
resource "azurerm_linux_virtual_machine" "stanlinux-vm" {
  name                  = "${var.prefix}-vm"
  resource_group_name   = azurerm_resource_group.rgstan.name
  location              = azurerm_resource_group.rgstan.location
  size                  = "Standard_B2s"
  admin_username        = "swaydevstan"
  network_interface_ids = [azurerm_network_interface.stan-nic.id]

  admin_ssh_key {
    username   = "swaydevstan"
    public_key = tls_private_key.swaydevstan-ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

#output vm IP address to connect to.
output "vm_public_ip_address" {
  value = azurerm_public_ip.stan-ip.ip_address
}


#To get the corresponding private key, run "terraform output -raw tls_private_key"
