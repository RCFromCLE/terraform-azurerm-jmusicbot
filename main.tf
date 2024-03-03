terraform {
  required_version = ">=0.12"
  # store state in Azure S3, resource group, storage account, container need to be created ahead of time.
  backend "azurerm" {
    resource_group_name  = "tfstaterg01"
    storage_account_name = "tfstate011503435350"
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

# configure the microsoft azure providers
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
  filename = "${path.module}/config.txt" # Ensure the path to config.txt is correct
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
      # Create a startup script
      "echo '#!/bin/bash' > /home/${var.vm_admin_username}/startup.sh",
      "echo '${var.remove_tfjdiscord_command}' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'sudo add-apt-repository -y ppa:openjdk-r/ppa' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'sudo apt-get update' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'sudo apt-get install -y ${var.java_version}' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'git clone ${var.repo_url}' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'cat <<EOF > ${var.jdiscord_path}/config.txt' >> /home/${var.vm_admin_username}/startup.sh",
      "echo '${data.local_file.config_txt.content}' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'EOF' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'cd ${var.jdiscord_path}' >> /home/${var.vm_admin_username}/startup.sh",
      "echo 'nohup sudo java -jar ${var.jdiscord_path}${var.jar_path} &' >> /home/${var.vm_admin_username}/startup.sh",

      # Make the script executable
      "chmod +x /home/${var.vm_admin_username}/startup.sh",

      # Schedule the script to run at boot
      "(crontab -l 2>/dev/null; echo '@reboot /home/${var.vm_admin_username}/startup.sh') | crontab -",
    ]
  }
}
output "vm_public_ip" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "The public IP address of the virtual machine."
}

# Assuming other parts of main.tf remain unchanged

# Azure Function App and related resources
resource "azurerm_storage_account" "functionapp_sa" {
  name                     = "jdiscord_sa_${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "functionapp_container" {
  name                  = "jdiscord-code"
  storage_account_name  = azurerm_storage_account.functionapp_sa.name
  container_access_type = "private"
}

resource "azurerm_app_service_plan" "functionapp_plan" {
  name                = "jdiscord-app-service-plan"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "jdiscord_function" {
  name                      = "jdiscord-function"
  location                  = azurerm_resource_group.rg1.location
  resource_group_name       = azurerm_resource_group.rg1.name
  app_service_plan_id       = azurerm_app_service_plan.functionapp_plan.id
  storage_account_name      = azurerm_storage_account.functionapp_sa.name
  storage_account_access_key = azurerm_storage_account.functionapp_sa.primary_access_key
  os_type                  = "linux"
  version                  = "~3"

  app_settings = {
    "DISCORD_BOT_TOKEN" = var.discord_bot_token
    # SPN needs to be created ahead of time and given virtual machine contributor role to the resource group or virtual machine
    "CLIENT_ID"         = var.azure_client_id
    "CLIENT_SECRET"     = var.azure_client_secret
    #"DOMAIN"            = var.azure_domain
    "SUBSCRIPTION_ID"   = var.sub
    "RESOURCE_GROUP_NAME" = azurerm_resource_group.rg1.name
    "VM_NAME"           = azurerm_linux_virtual_machine.vm1.name
  }
}

output "function_app_name" {
  value = azurerm_function_app.jdiscord_function.name
}

output "function_app_default_hostname" {
  value = azurerm_function_app.jdiscord_function.default_hostname
}
