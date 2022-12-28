$resource_group_name="tfstateRG01"
$storage_account_name="tfstate01$(get-random)"
$container_name='JDBtfstate'

#create rg
az group create --name $resource_group_name --location eastus

#create storage account
az storage account create --resource-group $resource_group_name --name $storage_account_name --location eastus

#create blob container - I could not get this step to work from CLI. Admittedly, I didn't try for that long. I just created it through the Azure portal to save time.
az storage container create --name $container_name --account-name $storage_account_name