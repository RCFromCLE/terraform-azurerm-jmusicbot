# azure subscription id
sub = "84dc7a07-cdff-47eb-8893-ab967507b6a4"
# resource group name and location
rg = "jdiscordbot-rg"
rg_loc = "eastus"
# virtual network name
net = "jdiscordbot-vnet"
# subnet name
subnet = "jdiscordbot-snet"
# public ip name
pub_ip = "jdb-pub_ip"
# network interface name
nic_name = "jdb-nic"
# private ip configuration name
nic_priv_ip_name = "jdb-priv_ip-config"
# vm name and size
vm_name = "jdb-vm"
vm_size = "Standard_B1ls"
# ssh key path
ssh_key_path_pub = "~/.ssh/id_rsa.pub"
ssh_key_path_priv = "~/.ssh/id_rsa"
# vm image publisher, offer, sku, and version
vm_image_publisher = "canonical"
vm_image_offer = "ubuntuserver"
vm_image_sku = "18_04-lts-gen2"
vm_image_version = "18.04.202103250"
# os disk name
os_disk_name = "os-disk"
# file share name
file_share_name = "jdb-files"
# quota
quota = 512
# disk size
disk_size = "50"
# iops
iops = 1000
# mbps
mbps = 100
# vm admin username
vm_admin_username = "rc"
# ommand to run on vm and launch JDB, modify version if changing to a new version
run_jdb = "java -jar ~/jdiscordmusicbot/JMusicBot-0.3.8.jar"