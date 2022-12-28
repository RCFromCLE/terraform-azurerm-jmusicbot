# azure subscription id
variable "sub" {
  type = string
}

# resource group name and location
variable "rg" {
  type    = string
  default = "jdiscordbot-rg"
}

variable "rg_loc" {
  type    = string
  default = "eastus"
}

# virtual network name
variable "net" {
  type    = string
  default = "jdiscordbot-vnet"
}

# subnet name
variable "subnet" {
  type    = string
  default = "jdiscordbot-snet"
}

# public ip name
variable "pub_ip" {
  type    = string
  default = "jdb-pub_ip"
}

# network interface name
variable "nic_name" {
  type    = string
  default = "jdb-nic"
}

# private ip configuration name
variable "nic_priv_ip_name" {
  type    = string
  default = "jdb-priv_ip-config"
}

# name of network security group
variable "nsg" {
  type    = string
  default = "jdb-nsg"
}
# vm name and size
variable "vm_name" {
  type    = string
  default = "jdb-vm"
}

variable "vm_size" {
  type    = string
  default = "Standard_B1ms"
}

# ssh key path
variable "ssh_key_path_pub" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
variable "ssh_key_path_priv" {
  type    = string
  default = "~/.ssh/id_rsa"

}
# vm image publisher, offer, sku, and version
variable "vm_image_publisher" {
  type    = string
  default = "canonical"
}

variable "vm_image_offer" {
  type    = string
  default = "ubuntuserver"
}

variable "vm_image_sku" {
  type    = string
  default = "18_04-lts-gen2"
}

variable "vm_image_version" {
  type    = string
  default = "18.04.202103250"
}

# os disk name
variable "os_disk_name" {
  type    = string
  default = "os-disk"

}

# disk size
variable "disk_size" {
  type    = string
  default = "50"
}

# iops
variable "iops" {
  type    = number
  default = 1000
}

# mbps
variable "mbps" {
  type    = number
  default = 100
}

# vm admin username
variable "vm_admin_username" {
  type    = string
  default = "rc"
}

# public ip allocation method
variable "pub_allocation_method" {
  type    = string
  default = "Dynamic"
}

# private ip allocation method
variable "priv_allocation_method" {
  type    = string
  default = "Dynamic"
}

# virtual machine extension public settings
variable "vm_extension_pub_settings" {
  type    = string
  default = "{\"commandtoexecute\":\"cd /mnt/jdiscordmusicbot && java -jar jmusicbot-0.3.8.jar\"}"
}

# virtual machine extension protected settings
variable "vm_extension_prot_settings" {
  type    = string
  default = "{}"
}

# virtual machine extension auto upgrade minor version
variable "vm_extension_auto_upgrade_minor_version" {
  type    = bool
  default = true
}
variable "run_jdb" {
  type    = string
  default = "java -jar ~tf-jdiscord/jdiscordmusicbot/JMusicBot-0.3.8.jar"
}
variable "jdb_local_path" {
  type    = string
  default = "jdiscordmusicbot"
}

variable "remove_tfjdiscord_command" {
  default = "[ -d \"tf-jdiscord\" ] && rm -rf tf-jdiscord"
}

variable "repo_url" {
  default = "https://github.com/RCFromCLE/tf-jdiscord.git"
}


variable "jdiscord_path" {
  default = "~/tf-jdiscord/jdiscordmusicbot"
}

variable "jar_path" {
  default = "/JMusicBot-0.3.8.jar"
}

variable "java_version" {
  type    = string
  default = "openjdk-8-jdk"
}
