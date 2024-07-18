variable "azure_tenant_id" {
  type        = string
  description = "The tenant ID of the Service Principal."
}

variable "sub" {
  type        = string
  description = "The subscription ID of the Azure subscription."
}

variable "rg" {
  type        = string
  description = "The name of the resource group."
  default     = "jdiscordbot-rg"
}

variable "rg_loc" {
  type        = string
  description = "The location of the resource group."
  default     = "eastus"
}

variable "net" {
  type        = string
  description = "The name of the virtual network."
  default     = "jdiscordbot-vnet"
}

variable "subnet" {
  type        = string
  description = "The name of the subnet."
  default     = "jdiscordbot-snet"
}

variable "pub_ip" {
  type        = string
  description = "The name of the public IP."
  default     = "jdb-pub_ip"
}

variable "nic_name" {
  type        = string
  description = "The name of the network interface."
  default     = "jdb-nic"
}

variable "nic_priv_ip_name" {
  type        = string
  description = "The name of the private IP configuration."
  default     = "jdb-priv_ip-config"
}

variable "nsg" {
  type        = string
  description = "The name of the network security group."
  default     = "jdb-nsg"
}

variable "vm_name" {
  type        = string
  description = "The name of the virtual machine."
  default     = "jdb-vm"
}

variable "vm_size" {
  type        = string
  description = "The size of the virtual machine."
  default     = "Standard_B1ms"
}
variable "vm_image_publisher" {
  type        = string
  description = "The publisher of the VM image."
  default     = "canonical"
}

variable "vm_image_offer" {
  type        = string
  description = "The offer of the VM image."
  default     = "ubuntuserver"
}

variable "vm_image_sku" {
  type        = string
  description = "The SKU of the VM image."
  default     = "18_04-lts-gen2"
}

variable "vm_image_version" {
  type        = string
  description = "The version of the VM image."
  default     = "18.04.202103250"
}

variable "os_disk_name" {
  type        = string
  description = "The name of the OS disk."
  default     = "os-disk"
}

variable "vm_admin_username" {
  type        = string
  description = "The admin username for the VM."
  default     = "rc"
}

variable "pub_allocation_method" {
  type        = string
  description = "The allocation method for the public IP."
  default     = "Dynamic"
}

variable "priv_allocation_method" {
  type        = string
  description = "The allocation method for the private IP."
  default     = "Dynamic"
}

variable "remove_tfjdiscord_command" {
  type        = string
  description = "The command to remove the tf-jdiscord directory."
  default     = "[ -d \"tf-jdiscord\" ] && rm -rf tf-jdiscord"
}

variable "repo_url" {
  type        = string
  description = "The URL of the GitHub repository."
  default     = "https://github.com/RCFromCLE/tf-jdiscord.git"
}

variable "jar_path" {
  type        = string
  description = "The path to the JMusicBot JAR file."
  default     = "JMusicBot-0.4.1.jar"
}

variable "discord_bot_token" {
  type        = string
  description = "The Discord bot token."
  sensitive   = true
}

variable "azure_client_id" {
  type        = string
  description = "The client ID of the Service Principal."
}

variable "azure_client_secret" {
  type        = string
  description = "The client secret of the Service Principal."
  sensitive   = true
}

variable "general_channel_id" {
  type        = string
  description = "The channel ID of the general channel in the Discord server."
}

variable "afk_channel_id" {
  type        = string
  description = "The channel ID of the AFK channel in the Discord server."
}

variable "music_channel_id" {
  type        = string
  description = "The channel ID of the music channel in the Discord server."
}

variable "discord_bot_owner" {
  type        = string
  description = "The owner ID for the Discord bot"
}

variable "discord_bot_prefix" {
  type        = string
  description = "The command prefix for the Discord bot"
  default     = "!"
}
variable "key_vault_name" {
  type        = string
  description = "The name of the key vault."
  default     = "jdiscord-kv"
}
variable "key_vault_resource_group_name" {
  type        = string
  description = "The name of the resource group for the key vault."
  default     = "jdiscord-kv-rg"    
}