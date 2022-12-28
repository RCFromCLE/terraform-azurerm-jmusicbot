terraform {
  required_version = ">=0.12"
  # store state in Azure S3, resource group, storage account, container need to be created ahead of time.
  backend "azurerm" {
    resource_group_name  = "tfstaterg01"
    storage_account_name = "tfstate01790900905"
    container_name       = "jdb-tf-state"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

# configure the microsoft azure provider
provider "azurerm" {
  features {}
  subscription_id = var.sub
}

# create a resource group
resource "azurerm_resource_group" "rg1" {
  name     = var.rg
  location = var.rg_loc
}

# create virtual network
resource "azurerm_virtual_network" "vnet1" {
  name                = var.net
  address_space       = ["10.0.0.0/23"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

# create subnet
resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

# create public ips
resource "azurerm_public_ip" "public_ip" {
  name                = var.pub_ip
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = var.pub_allocation_method
}

# create network security group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "inbound"
    access                     = "allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# create network interface
resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = var.nic_priv_ip_name
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = var.priv_allocation_method
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg_nic_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_linux_virtual_machine" "vm1" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.rg1.name
  location                        = azurerm_resource_group.rg1.location
  size                            = var.vm_size
  network_interface_ids           = [azurerm_network_interface.nic.id]
  disable_password_authentication = true
  admin_username                  = var.vm_admin_username

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(var.ssh_key_path_pub)
  }
  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = var.os_disk_name
  }
}
data "local_file" "config_txt" {
  filename = "config.txt"
}
resource "null_resource" "run_jdiscordbot" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.vm_admin_username
      host        = azurerm_linux_virtual_machine.vm1.public_ip_address
      private_key = file(var.ssh_key_path_priv)
    }
    inline = [
      "${var.remove_tfjdiscord_command}",
      "sudo add-apt-repository -y ppa:openjdk-r/ppa",
      "sudo apt-get update",
      "sudo apt-get install -y ${var.java_version}",
      "git clone ${var.repo_url}",
      "cat <<EOF > ${var.jdiscord_path}/config.txt",
      "${data.local_file.config_txt.content}",
      "EOF",
      "cd ${var.jdiscord_path}",
      "nohup sudo java -jar ${var.jdiscord_path}${var.jar_path} &",
      "sleep 10"
    ]
  }
}
