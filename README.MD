# terraform-azurerm-jmusicbot

This Terraform module deploys a JMusicBot instance into Azure, along with an Azure Function to manage the VM's lifecycle. The VM is only active when required, reducing costs.The module also creates a systemd service for JMusicBot, allowing it to start on boot and restart on failure. The Azure Function is triggered every 5 minutes, checking the presence of users in the Discord voice channel. If no users are present, the VM is deallocated. If users are present, the VM is started. The module also includes a systemd service for JMusicBot, allowing it to start on boot and restart on failure. 

## Features
- Automated VM Management via Azure Function.
- Linux systemd service creation for JMusicBot.
- VM is only active when required, reducing costs.
- Discord bot activity monitoring.

## Requirements
- An Azure subscription.
- An Azure Service Principal with the VM Contributor role at relevant subscription or resource group scope.
- Terraform 0.12 or newer.
- An existing Discord bot token.
- Discord channel IDs for activity monitoring.

## Usage
Include this module in your existing Terraform configuration to deploy JMusicBot into Azure:

```hcl
module "jmusicbot" {
  source  = "path/to/terraform-azurerm-jmusicbot"

  azure_tenant_id    = "your-tenant-id"
  sub                = "your-subscription-id"
  discord_bot_token  = "your-discord-bot-token"
  general_channel_id = "your-general-channel-id"
  afk_channel_id     = "your-afk-channel-id"
  azure_client_id    = "your-service-principal-client-id"
  azure_client_secret = "your-service-principal-client-secret"
}
```

Variables
---------

-   `azure_tenant_id`: The tenant ID for your Azure Service Principal.
-   `sub`: Your Azure subscription ID.
-   `rg`, `rg_loc`: Resource group name and location for your resources.
-   `net`, `subnet`, `pub_ip`, `nic_name`, `nsg`: Networking resource names.
-   `vm_name`, `vm_size`: Virtual machine name and size specifications.
-   `ssh_key_path_pub`, `ssh_key_path_priv`: SSH key paths for VM access.
-   `vm_image_publisher`, `vm_image_offer`, `vm_image_sku`, `vm_image_version`: VM image specifications.
-   `os_disk_name`, `disk_size`, `iops`, `mbps`: OS disk specifications.
-   `vm_admin_username`: Admin username for the VM.
-   `pub_allocation_method`, `priv_allocation_method`: IP allocation methods.
-   `discord_bot_token`: Your Discord bot token.
-   `azure_client_id`, `azure_client_secret`: Azure Service Principal credentials.
-   `general_channel_id`, `afk_channel_id`: Discord channel IDs for activity monitoring.

Outputs
-------

-   `vm_public_ip`: The public IP address of the deployed VM.
-   `function_app_name`: The name of the deployed Azure Function.
-   `function_app_default_hostname`: The default hostname for the function app.