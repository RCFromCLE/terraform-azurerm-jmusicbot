# azure subscription id
variable "sub" {
  type = string
}

# resource group name and location
variable "rg" {
  type = string
}

variable "rg_loc" {
  type = string
}

# virtual network name
variable "net" {
  type = string
}

# subnet name
variable "subnet" {
  type = string
}

# public ip name
variable "pub_ip" {
  type = string
}

# network interface name
variable "nic_name" {
  type = string
}

# private ip configuration name
variable "nic_priv_ip_name" {
  type = string
}

# name of network security group
variable "nsg" {
  type = string
  default = "jdb-nsg"
}
# vm name and size
variable "vm_name" {
  type = string
}

variable "vm_size" {
  type = string
}

# ssh key path
variable "ssh_key_path_pub" {
  type = string
}
variable "ssh_key_path_priv" {
  type = string

}
# vm image publisher, offer, sku, and version
variable "vm_image_publisher" {
  type = string
}

variable "vm_image_offer" {
  type = string
}

variable "vm_image_sku" {
  type = string
}

variable "vm_image_version" {
  type = string
}

# os disk name
variable "os_disk_name" {
  type = string
}

# storage account name
variable "sa_name" {
  type = string
  default = "jdb-stg-acct"
}
variable "md_name" {
    type = string
    default = "jdb-md"
}
# file share name
variable "file_share_name" {
  type = string
}

# quota
variable "quota" {
  type = number
}

# disk size
variable "disk_size" {
  type = string
}

# iops
variable "iops" {
  type = number
}

# mbps
variable "mbps" {
  type = number
}

# vm admin username
variable "vm_admin_username" {
  type = string
  default = "rc"
}

# public ip allocation method
variable "pub_allocation_method" {
  type = string
  default = "Dynamic"
}

# private ip allocation method
variable "priv_allocation_method" {
  type = string
  default = "Dynamic"
}

# virtual machine extension public settings
variable "vm_extension_pub_settings" {
  type = string
  default = "{\"commandtoexecute\":\"cd /mnt/jdiscordmusicbot && java -jar jmusicbot-0.3.8.jar\"}"
}

# virtual machine extension protected settings
variable "vm_extension_prot_settings" {
  type = string
  default = "{}"
}

# virtual machine extension auto upgrade minor version
variable "vm_extension_auto_upgrade_minor_version" {
  type = bool
  default = true
}
variable "run_jdb" {
  type = string
}
variable "jdb_local_path" {
  type = string
  default = "jdiscordmusicbot"
}

variable "custom_data_base64" {
  default = <<EOF
c3NoLWtleXNjYW4gJHtwdWJsaWNfaXBfYWRkcmVzc30gPj4gfi8uc3NoL2tub3du
X2hvc3RzCnNjcCAtciAtaSB+Ly5zc2gvaWRfcnNhIGpkaXNjb3JkbXVzaWNib3Qg
cmNAJHtwdWJsaWNfaXBfYWRkcmVzc306fi8Kc3VkbyBhcHQtZ2V0IHVwZGF0ZQpz
dWRvIGFwdC1nZXQgaW5zdGFsbCAteSBvcGVuamRrLTgtamRrCiR7dmFyLnJ1bl9q
ZGJ9Cg==
EOF
}
