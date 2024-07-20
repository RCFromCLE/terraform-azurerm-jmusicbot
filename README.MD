# terraform-azure-jmusicbot

This Terraform module deploys JMusicBot on Azure, providing a robust and cost-effective solution for Discord server owners and an excellent practice project for Azure DevOps engineers. The module strongly recommends deployment and management via Terraform Cloud for optimal performance and security.

## Key Features

- **Complete Infrastructure**: Sets up all necessary Azure resources for running JMusicBot.

- **Automated Lifecycle Management**: Utilizes an Azure Function (`jdiscord-function`) to dynamically manage the VM.
  - Starts the VM when users join the music channel.
  - Stops the VM when all users leave voice channels.
- **Continuous Updates**: Includes a GitHub Actions workflow to keep JMusicBot up-to-date with the latest releases.
- **Fully Automated Deployment**: When using the configuration repository, the "Check for Module Update and TF Apply" action can automatically apply new releases created by the update-jar action.

[![update-jar-and-release](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot/actions/workflows/update-jar.yml/badge.svg)](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot/actions/workflows/update-jar.yml)

This module offers a fully automated deployment and update process, making it an ideal solution for Discord server owners looking to provide a reliable music bot service. For Azure DevOps engineers, it presents a comprehensive project that combines Infrastructure as Code, serverless computing, and CI/CD practices in a real-world application.

## Requirements

To use this module, you'll need:

1. **Azure Subscription**: An active Azure subscription with sufficient permissions to create resources.

2. **Terraform**: Version 0.12 or later installed on your local machine and system path environmnt variable set.

3. **Terraform Cloud Account**: A Terraform Cloud account for state management and secure variable storage.

4. **Azure Service Principal**: An Azure AD application and service principal with Contributor access to your Azure subscription. You'll need:
   - Client ID
   - Client Secret
   - Tenant ID
   - Subscription ID

5. **Discord Bot**: A created Discord bot with the following:
   - Bot Token (for authentication to your Discord server)
   - Bot Owner ID (your personal Discord ID)
   - General Channel ID (not used in this version but required for future updates)
   - Music Channel ID (All bot communication will be done in this channel)
   - AFK Channel ID (Bot will ignore users in this channel)

See JMusicBot's wiki for more information on setting up a Discord bot: [JMusicBot Wiki](https://jmusicbot.com/getting-a-bot-token/)

6. **GitHub Account**: Required for the automated update workflow and forked configuration repository.

7. **Azure CLI**: Installed and configured for local testing and deployment.

8. **PowerShell**: For running the `set_workspace_variables.ps1` script (Windows environments).

9. **VS Code** (recommended): With the following extensions:
    - Azure tools
    - GitHub Actions
    - Terraform - HashiCorp

10. **Configuration Repository**: A forked copy of the [terraform-azurerm-jmusicbot-config](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config) repository for managing the infrastructure configuration.

Ensure all these components are set up before attempting to deploy the module. Refer to the configuration repository for detailed setup instructions for each requirement.

## Usage

1. Configure Terraform Cloud in your configuration:

```hcl
terraform {
  cloud {
    organization = "YourOrganization"
    workspaces {
      name = "azure-jmusicbot"
    }
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
```

2. In your Terraform configuration, reference this module:

```hcl
"jmusicbot" {
  source  = "RCFromCLE/jmusicbot/azure"
  version = "1.3.5"

  # Required variables
  azure_tenant_id     = var.azure_tenant_id
  sub                 = var.sub
  discord_bot_token   = var.discord_bot_token
  discord_bot_owner   = var.discord_bot_owner
  general_channel_id  = var.general_channel_id
  music_channel_id    = var.music_channel_id
  afk_channel_id      = var.afk_channel_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret

  # Optional variables
  rg                    = var.rg
  rg_loc                = var.rg_loc
  net                   = var.net
  subnet                = var.subnet
  pub_ip                = var.pub_ip
  nic_name              = var.nic_name
  nsg                   = var.nsg
  vm_name               = var.vm_name
  vm_size               = var.vm_size
  vm_image_publisher    = var.vm_image_publisher
  vm_image_offer        = var.vm_image_offer
  vm_image_sku          = var.vm_image_sku
  vm_image_version      = var.vm_image_version
  os_disk_name          = var.os_disk_name
  vm_admin_username     = var.vm_admin_username
  discord_bot_prefix    = var.discord_bot_prefix
}
```

3. Provide values for the required variables in your Terraform Cloud workspace or `terraform.tfvars` file.

## Resources Deployed

This module deploys the following Azure resources:

1. **Resource Group**: Contains all deployed resources
2. **Virtual Network**: Network infrastructure for the VM
3. **Subnet**: Subnetwork within the VNet for the VM
4. **Network Security Group**: Defines inbound and outbound security rules
5. **Public IP**: Allocates a public IP address for the VM
6. **Network Interface**: Virtual network interface for the VM
7. **Linux Virtual Machine**: Hosts the JMusicBot application
8. **Virtual Machine Extension**: Custom script extension to set up JMusicBot
9. **Storage Account**: Used by the Function App
10. **App Service Plan**: Hosts the Function App
11. **Application Insights**: Provides monitoring for the Function App
12. **Function App**: Hosts the Node.js function that manages VM lifecycle

## Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `azure_tenant_id` | string | The tenant ID of the Azure Service Principal | |
| `sub` | string | The subscription ID of the Azure subscription | |
| `discord_bot_token` | string | The Discord bot token | |
| `discord_bot_owner` | string | The owner ID for the Discord bot | |
| `general_channel_id` | string | The channel ID of the general channel in the Discord server | |
| `music_channel_id` | string | The channel ID of the music channel in the Discord server | |
| `afk_channel_id` | string | The channel ID of the AFK channel in the Discord server | |
| `azure_client_id` | string | The client ID of the Azure Service Principal | |
| `azure_client_secret` | string | The client secret of the Azure Service Principal | |
| `rg` | string | The name of the resource group | "jdiscordbot-rg" |
| `rg_loc` | string | The location of the resource group | "eastus" |
| `net` | string | The name of the virtual network | "jdiscordbot-vnet" |
| `subnet` | string | The name of the subnet | "jdiscordbot-snet" |
| `pub_ip` | string | The name of the public IP | "jdb-pub_ip" |
| `nic_name` | string | The name of the network interface | "jdb-nic" |
| `nsg` | string | The name of the network security group | "jdb-nsg" |
| `vm_name` | string | The name of the virtual machine | "jdb-vm" |
| `vm_size` | string | The size of the virtual machine | "Standard_B1ms" |
| `vm_image_publisher` | string | The publisher of the VM image | "canonical" |
| `vm_image_offer` | string | The offer of the VM image | "ubuntuserver" |
| `vm_image_sku` | string | The SKU of the VM image | "18_04-lts-gen2" |
| `vm_image_version` | string | The version of the VM image | "18.04.202103250" |
| `os_disk_name` | string | The name of the OS disk | "os-disk" |
| `vm_admin_username` | string | The admin username for the VM | "rc" |
| `discord_bot_prefix` | string | The command prefix for the Discord bot | "!" |

## Outputs

- `vm_public_ip`: The public IP address of the deployed VM
- `function_app_name`: The name of the deployed Azure Function App

## Function App

The module includes an Azure Function (`jdiscord-function/index.js`) that manages the VM lifecycle based on Discord activity. It:

- Monitors Discord voice channels
- Starts the VM when users join the music channel
- Stops the VM when all users leave voice channels
- Starts the VM when atleast one user is in the music channel
- Ignores users in the AFK channel
- Responds to manual "start music bot" commands

## Automated Updates

The module includes a GitHub Actions workflow (`update-jar.yml`) that:

- Checks daily @ 5 AM EST for new JMusicBot releases
- Updates the JAR file when a new version is available
- Updates the `variables.tf` file with the new JAR version
- Creates a new release in the repository

## Configuration Repository

For detailed setup instructions and a complete configuration example, refer to the [terraform-azurerm-jmusicbot-config](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config) repository.

## Notes

- This module is designed to work with Terraform Cloud
- Ensure your Azure service principal has the necessary permissions
- See configuration repository action called "Check for Module Update and TF Apply" for how to apply the new release created by update-jar action
- Keep sensitive variables secure in Terraform Cloud or `terraform.tfvars`
- Forking this module is not necessary unless you have specific security requirements

[Terraform Registry page](https://registry.terraform.io/modules/RCFromCLE/jmusicbot/azure/latest) for this module.

## Contributing

Contributions are welcome! Please submit pull requests with any enhancements or bug fixes.