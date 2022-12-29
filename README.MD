terraform-azure-jmusicbot
========================

This module installs, configures, and runs JMusicBot (https://jmusicbot.com/) on an Ubuntu 18 instance hosted in Azure cloud. Simply fill in the sub variable in the terraform.tfvars file and run a terraform init, terraform plan, terraform apply. 

https://rudycorradetti.com/2022/12/29/tf-jdiscord-deploying-jmusicbot-in-azure-using-terraform/

https://registry.terraform.io/modules/RCFromCLE/jmusicbot/azure/latest?tab=inputs


Requirements
------------

-   A valid Azure subscription
-   Terraform 0.12 or later
-   Discord API token from your server. https://jmusicbot.com/adding-your-bot/
-   Azure S3 resources need to be precreated

Providers
---------

-   azurerm
-   tls
-   random
-   null
-   local

Inputs
------

| Name | Description | Type | Default | Required |
| --- | --- | --- | --- | --- |
| pub_allocation_method | The method to allocate public IP address | string | "Dynamic" | no |
| priv_allocation_method | The method to allocate private IP address | string | "Dynamic" | no |
| sub | Azure subscription ID | string | n/a | yes |
| rg | Name of the resource group | string | n/a | yes |
| rg_loc | Location of the resource group | string | n/a | yes |
| net | Name of the virtual network | string | n/a | yes |
| subnet | Name of the subnet | string | n/a | yes |
| pub_ip | Name of the public IP | string | n/a | yes |
| nsg | Name of the network security group | string | n/a | yes |
| nic_name | Name of the network interface | string | n/a | yes |
| nic_priv_ip_name | Name of the private IP for the network interface | string | n/a | yes |
| vm_name | Name of the virtual machine | string | n/a | yes |
| vm_size | Size of the virtual machine | string | "Standard_B1s" | no |
| vm_image_publisher | Publisher of the virtual machine image | string | "Canonical" | no |
| vm_image_offer | Offer of the virtual machine image | string | "UbuntuServer" | no |
| vm_image_sku | SKU of the virtual machine image | string | "18.04-LTS" | no |
| vm_os_disk_name | Name of the OS disk for the virtual machine | string | n/a | yes |
| vm_os_disk_caching | Caching behavior of the OS disk | string | "ReadWrite" | no |
| vm_os_disk_create_option | Create option for the OS disk | string | "FromImage" | no |

Outputs
-------

| Name | Description |
| --- | --- |
| public_ip_address | The public IP address of the virtual machine |
| private_ip_address | The private IP address of the virtual machine |
| network_interface_id | The ID of the network interface |

Usage
-----

To use this module, add the following block to your Terraform configuration:

```
module "jdiscord" {
  source = "git::https://github.com/RCFromCLE/tf-jdiscord.git"

  sub               = var.sub

```
