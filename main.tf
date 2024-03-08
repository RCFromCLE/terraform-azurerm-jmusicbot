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
      version = "~>3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

# configure providers
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
data "azurerm_public_ip" "vm_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.rg1.name
}


resource "azurerm_virtual_machine_extension" "custom_script_extension" {
  name                 = "startup-jdiscord-script"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm1.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    "fileUris": [],
    "commandToExecute": "bash -c '${base64decode(base64encode(join("\n", [
        "${var.remove_tfjdiscord_command}",
        "sudo add-apt-repository -y ppa:openjdk-r/ppa",
        "sudo apt-get update",
        "sudo apt-get install -y ${var.java_version}",
        "git clone ${var.repo_url}",
        "cat <<EOF > ${var.jdiscord_path}/config.txt",
        "${data.local_file.config_txt.content}",
        "EOF",
        "cd ${var.jdiscord_path}", // Change directory to jdiscordmusicbot
        "sudo java -jar ${var.jar_path}",
        "sleep 10"
      ])))}'"
  })
}
  
output "vm_public_ip" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "The public IP address of the virtual machine."
}

resource "random_string" "sa_suffix" {
  length  = 5  # Adjusted length for the suffix
  special = false
  upper   = false
  numeric  = true
  lower   = true  # Ensure lowercase is explicitly stated, though it's the default
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
# appplan for function app
# Linux app service plan.
resource "azurerm_service_plan" "functionapp_plan" {
  name                = "jdiscord-app-service-plan"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  os_type             = "Linux"
  sku_name            = "Y1"  # "Y1" is the SKU for the Consumption plan.
}

# Application insights for monitoring.
resource "azurerm_application_insights" "app_insights" {
  name                = "jdiscord-appinsights"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  application_type    = "web"
}

# Linux function app.
# resource "azurerm_linux_function_app" "jdiscord_function" {
#   name                      = "jdiscord-function"
#   location                  = azurerm_resource_group.rg1.location
#   resource_group_name       = azurerm_resource_group.rg1.name
#   service_plan_id           = azurerm_service_plan.functionapp_plan.id
#   storage_account_name      = azurerm_storage_account.functionapp_sa.name
#   storage_account_access_key = azurerm_storage_account.functionapp_sa.primary_access_key
#   app_settings = {
#     "FUNCTIONS_WORKER_RUNTIME" = "node"
#     "GENERAL_CHANNEL_ID"       = var.general_channel_id
#     "AFK_CHANNEL_ID"           = var.afk_channel_id
#     "DISCORD_BOT_TOKEN"        = var.discord_bot_token
#     "AZURE_CLIENT_ID"          = var.azure_client_id
#     "AZURE_CLIENT_SECRET"      = var.azure_client_secret
#     "SUBSCRIPTION_ID"          = var.sub
#     "RESOURCE_GROUP_NAME"      = azurerm_resource_group.rg1.name
#     "VM_NAME"                  = var.vm_name  # Assuming you have this defined elsewhere or passed as a variable.
#     "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key
#   }

#   site_config {}

# }
# output "function_app_name" {
#   value       = azurerm_linux_function_app.jdiscord_function.name
#   description = "The name of the function app."
# }

# output "function_app_default_hostname" {
#   value       = azurerm_linux_function_app.jdiscord_function.default_hostname
#   description = "The default hostname of the function app."
# }

output "application_insights_name" {
  value       = azurerm_application_insights.app_insights.name
  description = "The name of the Application Insights component."
}