# author: Rudy Corradetti
############################################ terraform and provider blocks ############################################
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
  }
}
provider "azurerm" {
  features {}
  subscription_id = var.sub
}

############################################ data sources ############################################
# data "azurerm_key_vault" "jdiscord_kv" {
#   name                = var.key_vault_name
#   resource_group_name = var.key_vault_resource_group_name
# }

# data "azurerm_key_vault_secret" "ssh_public_key" {
#   name         = "ssh-public-key"
#   key_vault_id = data.azurerm_key_vault.jdiscord_kv.id
# }

# locals {
#   ssh_public_key = trimspace(data.azurerm_key_vault_secret.ssh_public_key.value)
# }
############################################ resource blocks ############################################
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
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
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
# create a private key for the virtual machine
resource "tls_private_key" "linux_test_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# create a virtual machine run jdiscordbot service
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
  lifecycle {
    ignore_changes = [boot_diagnostics]
  }
}
data "azurerm_public_ip" "vm_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.rg1.name
}
resource "azurerm_virtual_machine_extension" "run_jdiscordbot" {
  name                 = "run_jdiscordbot"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm1.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    "script" : base64encode(<<-EOT
#!/bin/bash
set -e

# Enable error logging
exec 2>/tmp/vm_extension_error.log

echo "Starting JDiscordBot setup script..."

# Use the jar_path variable passed from Terraform
JAR_FILE="${var.jar_path}"

# Update and install dependencies
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install -y default-jdk curl

echo "Java installed successfully."

# Stop and disable the existing service
sudo systemctl stop jdiscordbot.service || true
sudo systemctl disable jdiscordbot.service || true

echo "Existing service stopped and disabled."

# Remove existing files
sudo rm -rf /home/${var.vm_admin_username}/tf-jdiscord

echo "Old files removed."

# Create directory structure
sudo mkdir -p /home/${var.vm_admin_username}/tf-jdiscord/jdiscordmusicbot
cd /home/${var.vm_admin_username}/tf-jdiscord/jdiscordmusicbot

echo "Directory structure created."

# Download JMusicBot JAR file
sudo curl -L -o $JAR_FILE https://github.com/jagrosh/MusicBot/releases/download/0.4.3/$JAR_FILE

echo "JMusicBot JAR file downloaded."

# Create new config file
cat << EOF | sudo tee config.txt
token = ${var.discord_bot_token}
owner = ${var.discord_bot_owner}
prefix = "${var.discord_bot_prefix}"
EOF

echo "Config file created."

# Set proper permissions
sudo chown -R ${var.vm_admin_username}:${var.vm_admin_username} /home/${var.vm_admin_username}/tf-jdiscord
sudo chmod 644 config.txt
sudo chmod 755 /home/${var.vm_admin_username}/tf-jdiscord/jdiscordmusicbot

echo "Permissions set."

# Verify the JAR file exists
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: JMusicBot JAR file not found" >&2
    exit 1
fi

echo "JAR file verified."

# Create new service file
cat << EOF | sudo tee /etc/systemd/system/jdiscordbot.service
[Unit]
Description=JDiscordBot Service
After=network.target

[Service]
Type=simple
User=${var.vm_admin_username}
WorkingDirectory=/home/${var.vm_admin_username}/tf-jdiscord/jdiscordmusicbot
ExecStart=/usr/bin/java -jar $JAR_FILE
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "Service file created."

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable jdiscordbot.service
sudo systemctl start jdiscordbot.service

echo "Service enabled and started."

# Verify the service is running
sudo systemctl status jdiscordbot.service

# Execute custom removal command if provided
${var.remove_tfjdiscord_command}

echo "JDiscordBot setup completed successfully"
EOT
    )
  })
  depends_on = [azurerm_linux_virtual_machine.vm1]
}
# Create a random string for the storage account name
resource "random_string" "sa_suffix" {
  length  = 5 # Adjusted length for the suffix
  special = false
  upper   = false
  numeric = true
  lower   = true # Ensure lowercase is explicitly stated, though it's the default
}
# storage account for function app
resource "azurerm_storage_account" "functionapp_sa" {
  name                     = "jdiscordstorage${random_string.sa_suffix.result}"
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
# Linux app service plan.
resource "azurerm_service_plan" "functionapp_plan" {
  name                = "jdiscord-app-service-plan"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  os_type             = "Linux"
  sku_name            = "Y1" # "Y1" is the SKU for the Consumption plan.
}
# Application insights for monitoring.
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
    "FUNCTIONS_WORKER_RUNTIME"       = "node"                 # This is the runtime for the function app, do not change this unless you know what you're doing.
    "GENERAL_CHANNEL_ID"             = var.general_channel_id # this is the channel id for the general channel where the music bot will send status updates
    "AFK_CHANNEL_ID"                 = var.afk_channel_id     # this is the channel id for the afk channel
    "MUSIC_CHANNEL_ID"               = var.music_channel_id   # this is the channel id for the music bot channel
    "DISCORD_BOT_TOKEN"              = var.discord_bot_token  # this is the bot token
    "AZURE_TENANT_ID"                = var.azure_tenant_id
    "AZURE_CLIENT_ID"                = var.azure_client_id # this is the client id of the service principal - grant sp access to the resource group or subscription to reboot the vm
    "AZURE_CLIENT_SECRET"            = var.azure_client_secret
    "SUBSCRIPTION_ID"                = var.sub
    "RESOURCE_GROUP_NAME"            = azurerm_resource_group.rg1.name
    "VM_NAME"                        = var.vm_name # Assuming you have this defined elsewhere or passed as a variable.
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key
  }
  site_config {
    application_stack {
      node_version = "18" # This is the version of node that the function app will use. Do not change this unless you know what you're doing.
    }
  }
  lifecycle {
    ignore_changes = [
      app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      site_config[0].application_insights_key,
    ]
  }
}
