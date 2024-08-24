# author: Rudy Corradetti
terraform {
  required_version = ">=0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.sub
}

# Data source to fetch latest release information
data "http" "latest_release" {
  url = "https://api.github.com/repos/jagrosh/MusicBot/releases/latest"
  request_headers = {
    Accept = "application/vnd.github.v3+json"
  }
}

locals {
  latest_version = jsondecode(data.http.latest_release.response_body).tag_name
  jar_filename   = "JMusicBot-${local.latest_version}.jar"
  download_url   = "https://github.com/jagrosh/MusicBot/releases/download/${local.latest_version}/${local.jar_filename}"
}

# Create a random string for the storage account name
resource "random_string" "sa_suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# Resource group
resource "azurerm_resource_group" "rg1" {
  name     = var.rg
  location = var.rg_loc
}

# Virtual network
resource "azurerm_virtual_network" "vnet1" {
  name                = var.net
  address_space       = ["10.0.0.0/23"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

# Subnet
resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = var.pub_ip
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = var.pub_allocation_method
}

# Network security group
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network interface
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

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg_nic_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# SSH key
resource "tls_private_key" "linux_test_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Virtual machine
resource "azurerm_linux_virtual_machine" "vm1" {
  name                            = var.vm_name
  location                        = azurerm_resource_group.rg1.location
  resource_group_name             = azurerm_resource_group.rg1.name
  network_interface_ids           = [azurerm_network_interface.nic.id]
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.linux_test_ssh.public_key_openssh
  }

  os_disk {
    name                 = var.os_disk_name
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [boot_diagnostics]
  }
}

# Storage account for JMusicBot
resource "azurerm_storage_account" "jmusicbot_storage" {
  name                     = "jmusicbotstorage${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container in the storage account
resource "azurerm_storage_container" "jmusicbot_container" {
  name                  = "jmusicbot-files"
  storage_account_name  = azurerm_storage_account.jmusicbot_storage.name
  container_access_type = "private"
}

# Upload the JAR file to the storage account
resource "azurerm_storage_blob" "jmusicbot_jar" {
  name                   = local.jar_filename
  storage_account_name   = azurerm_storage_account.jmusicbot_storage.name
  storage_container_name = azurerm_storage_container.jmusicbot_container.name
  type                   = "Block"
  source_uri             = local.download_url
}

# Role assignment for VM to access storage
# resource "azurerm_role_assignment" "vm_storage_blob_reader" {
#   scope                = azurerm_storage_account.jmusicbot_storage.id
#   role_definition_name = "Storage Blob Data Reader"
#   principal_id         = azurerm_linux_virtual_machine.vm1.identity[0].principal_id
#   depends_on = [azurerm_linux_virtual_machine.vm1]
# }
# VM extension to set up JMusicBot
resource "azurerm_virtual_machine_extension" "setup_jmusicbot" {
  name                 = "setup_jmusicbot"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm1.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    "script" : base64encode(<<-EOT
#!/bin/bash
set -e

echo "Starting JMusicBot setup..."

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Java
sudo apt-get update
sudo apt-get install -y default-jre

# Create directory for JMusicBot
sudo mkdir -p /opt/jmusicbot
cd /opt/jmusicbot

# Use managed identity to authenticate Azure CLI
az login --identity

# Download JAR file from Azure Storage
az storage blob download --account-name ${azurerm_storage_account.jmusicbot_storage.name} \
                         --container-name ${azurerm_storage_container.jmusicbot_container.name} \
                         --name ${local.jar_filename} \
                         --file ${local.jar_filename} \
                         --auth-mode login

# Create config file
cat << EOF > config.txt
token = ${var.discord_bot_token}
owner = ${var.discord_bot_owner}
prefix = "${var.discord_bot_prefix}"
EOF

# Create systemd service file
cat << EOF | sudo tee /etc/systemd/system/jmusicbot.service
[Unit]
Description=JMusicBot Service
After=network.target

[Service]
ExecStart=/usr/bin/java -Dnogui=true -jar /opt/jmusicbot/${local.jar_filename}
WorkingDirectory=/opt/jmusicbot
User=nobody
Group=nogroup
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
sudo chown -R nobody:nogroup /opt/jmusicbot
sudo chmod 644 /opt/jmusicbot/${local.jar_filename}
sudo chmod 644 /opt/jmusicbot/config.txt

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable jmusicbot.service
sudo systemctl start jmusicbot.service

echo "JMusicBot setup completed."
EOT
    )
  })

  depends_on = [
    azurerm_storage_blob.jmusicbot_jar,
    azurerm_linux_virtual_machine.vm1,
    # azurerm_role_assignment.vm_storage_blob_reader
  ]
}

# Storage account for function app
resource "azurerm_storage_account" "functionapp_sa" {
  name                     = "jdiscord${random_string.sa_suffix.result}"
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

# Linux app service plan
resource "azurerm_service_plan" "functionapp_plan" {
  name                = "jdiscord-app-service-plan"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Application insights for monitoring
resource "azurerm_application_insights" "app_insights" {
  name                = "jdiscord-appinsights"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  application_type    = "web"
}

# Linux function app
resource "azurerm_linux_function_app" "jdiscord_function" {
  name                       = "jdiscord-function"
  location                   = azurerm_resource_group.rg1.location
  resource_group_name        = azurerm_resource_group.rg1.name
  service_plan_id            = azurerm_service_plan.functionapp_plan.id
  storage_account_name       = azurerm_storage_account.functionapp_sa.name
  storage_account_access_key = azurerm_storage_account.functionapp_sa.primary_access_key
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "node"
    "GENERAL_CHANNEL_ID"             = var.general_channel_id
    "AFK_CHANNEL_ID"                 = var.afk_channel_id
    "MUSIC_CHANNEL_ID"               = var.music_channel_id
    "DISCORD_BOT_TOKEN"              = var.discord_bot_token
    "AZURE_TENANT_ID"                = var.azure_tenant_id
    "AZURE_CLIENT_ID"                = var.azure_client_id
    "AZURE_CLIENT_SECRET"            = var.azure_client_secret
    "SUBSCRIPTION_ID"                = var.sub
    "RESOURCE_GROUP_NAME"            = azurerm_resource_group.rg1.name
    "VM_NAME"                        = var.vm_name
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key
  }
  
  site_config {
    application_stack {
      node_version = "18"
    }
  }
  
  lifecycle {
    ignore_changes = [
      app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      site_config[0].application_insights_key,
    ]
  }
}