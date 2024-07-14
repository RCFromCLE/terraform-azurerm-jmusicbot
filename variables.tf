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

variable "ssh_key_path_pub" {
  type        = string
  description = "The path to the public SSH key."
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_key_path_priv" {
  type        = string
  description = "The path to the private SSH key."
  default     = "~/.ssh/id_rsa"
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

variable "disk_size" {
  type        = string
  description = "The size of the disk in GB."
  default     = "50"
}

variable "iops" {
  type        = number
  description = "The number of IOPS."
  default     = 1000
}

variable "mbps" {
  type        = number
  description = "The throughput in MB per second."
  default     = 100
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

variable "vm_extension_pub_settings" {
  type        = string
  description = "The public settings for the VM extension."
  default     = "{\"commandtoexecute\":\"cd /mnt/jdiscordmusicbot && java -jar JMusicBot-0.4.1.jar\"}"
}

variable "vm_extension_prot_settings" {
  type        = string
  description = "The protected settings for the VM extension."
  default     = "{}"
}

variable "vm_extension_auto_upgrade_minor_version" {
  type        = bool
  description = "Whether to auto-upgrade minor versions of the VM extension."
  default     = true
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

variable "java_version" {
  type        = string
  description = "The version of Java to install."
  default     = "openjdk-8-jdk"
}

variable "discord_bot_token" {
  type        = string
  description = "The Discord bot token."
}

variable "azure_client_id" {
  type        = string
  description = "The client ID of the Service Principal."
}

variable "azure_client_secret" {
  type        = string
  description = "The client secret of the Service Principal."
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