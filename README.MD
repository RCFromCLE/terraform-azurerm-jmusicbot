# terraform-azurerm-jmusicbot

## Introduction

This Terraform module deploys JMusicBot on Azure, offering a robust and cost-effective solution for Discord server owners while serving as an excellent practice project for Azure-Terraform platform engineers. For optimal performance and security, deployment and management via Terraform Cloud is strongly recommended.

![logo](images/logo.png) 

### What is JMusicBot?

[![Build and Test](https://github.com/jagrosh/MusicBot/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/jagrosh/MusicBot/actions/workflows/build-and-test.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/jagrosh/MusicBot)

JmusicBot is a Discord music bot that plays music in voice channels from all kinds of sources (YouTube being the primary). It is a Java application that requires a Linux or Windows machine to run. This module sets up all necessary Azure resources for running JMusicBot, including a Linux VM, Function App, and associated networking resources. The Azure Function dynamically manages the VM lifecycle based on Discord activity, starting the VM when users join the music channel and stopping it when all users leave voice channels. GitHub Actions working together with Terraform Cloud runs keep JMusicBot up-to-date with the latest releases, ensuring your bot is always running the latest version.

[![update-jar-and-release](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot/actions/workflows/update-jar.yml/badge.svg)](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot/actions/workflows/update-jar.yml)

Why Did I Create This Project?

I have been running JMusicBot locally first then I realized that wasn't sustainable as whenever I went offline the bot also went offline. I then moved to Azure with a standard B1 VM, this worked for a while but it was costing 20-30 dollars per month. I then implemented the Azure Function to start and stop the VM when users joined and left the music channel. This reduced the cost to 0.00 when no one was using the bot. I then realized that I could automate the updates with GitHub Actions and Terraform Cloud. This project is the result of that realization. The goal of this project is to provide a completely automated solution for running JMusicBot on Azure with minimal cost and maintenance ad to provide a practical project for learning Azure, Terraform, and GitHub Actions.

In the future, I plan to add more features to the Azure Function such as top ten songs played, top ten users, also need to automate the discord bot token rotation as Discord has revoked my token due to "abuse suspected" as the bot connected to a server so many times within a short time period. For now, one would need to manually rotate the token in the Terraform Cloud workspace, rerun the workspace, and then restart the Azure Function App.


## Key Features

- **Complete Infrastructure**: Sets up all necessary Azure resources for running JMusicBot.

- **Automated Lifecycle Management**: Utilizes an Azure Function (`jdiscord-function`) to dynamically manage the VM.
  - Starts the VM when users join the music channel.
  - Stops the VM when all users leave voice channels.

- **Continuous Updates**: Includes a GitHub Actions workflow to keep JMusicBot up-to-date with the latest releases.

- **Fully Automated Deployment**: When using the configuration repository, the "Check for Module Update and TF Apply" action can automatically apply new releases created by the update-jar action.

- **Secure Configuration**: Sensitive variables are stored securely in Terraform Cloud or `terraform.tfvars` Key Vault, and GitHub Actions secrets. See configuration repository for how we use an Azure Key Vault, Terraform Cloud workspace variables, variable sets, and GitHub Actions secrets to secure sensitive information used in this project.

- **Cost-Effective**: Utilizes serverless computing with Azure Functions. The consumption-based pricing model ensures you only pay for what you use and your first 1 million requests are free. This solution will never come close to that. Cost will be 0.00 for the Azure Function in this solution.

- **Real-World Application**: Combines Infrastructure as Code, an open source Java app, serverless computing, and CI/CD practices in a practical project.

## Requirements

To use this module, you'll need:

1. **Azure Subscription**: An active Azure subscription with sufficient permissions to create resources. I created a new subscription for this project. You can use an existing subscription but be aware of the costs associated with running the VM and Function App and you will need to think about custom permissions for the service principal if you are using an existing subscription.

2. **Terraform**: Version 0.12 or later installed on your local machine and system path environmnt variable set.

3. **Terraform Cloud Account**: A Terraform Cloud account for state management and secure variable storage. This is required for the infrastructure deployment, state management, secure variable storage and update workflows. You can sign up for a free account at [Terraform Cloud](https://app.terraform.io/signup/account).

4. **Azure Service Principal**: An Azure AD application and service principal with owner access to your newly created Azure subscription. Or a custom role for an existing subscription, which is out of scope for this project. I used owner so I am not sure what the exact permissions this project requires. The following information is required for the service principal:

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

9. **VS Code** (recommended): With the following extensions:
    - Azure tools
    - PowerShell
    - GitHub Actions
    - Terraform - HashiCorp
    - HCP - Terraform

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

3. Provide values for the required variables in your Terraform Cloud workspace or `terraform.tfvars` file. You can use set_workspace_variable.ps1 to set the variables in the TF Cloud Workspace. Simply fill out your Terraform API token, place the script in the same directory as terraform.tfvars and run the script.

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

- This module is designed to run within a Terraform Cloud workspace in concert with the jdiscord-kv workspace. See the configuration repository for detailed setup instructions.
- Ensure your Azure service principal has the necessary permissions  (owner over your musicbot subscription) to create resources.
- See configuration repository action called "Check for Module Update and TF Apply" for how to apply the new release created by update-jar action
- Keep sensitive variables secure in Terraform Cloud or `terraform.tfvars` never in variables.tf as it could be exposed in the GitHub repository.
- Forking this module is not necessary unless you have specific security requirements

[Terraform Registry page](https://registry.terraform.io/modules/RCFromCLE/jmusicbot/azure/latest) for this module.

## Contributing

Contributions are welcome! Please submit pull requests with any enhancements or bug fixes.