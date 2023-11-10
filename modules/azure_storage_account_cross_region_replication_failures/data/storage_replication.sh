#!/bin/bash

# Source storage account details
source_resource_group=${RESOURCE_GROUP_NAME}
source_storage_account=${STORAGE_ACCOUNT_NAME}
source_location=$(az storage account show --resource-group $source_resource_group --name $source_storage_account --query location -o tsv)

# Target storage account details
target_resource_group=${TARGET_RESOURCE_GROUP}
target_storage_account=${TARGET_STORAGE_ACCOUNT_NAME}
target_location=${TARGET_STORAGE_ACCOUNT_REGION}

# Fetch source storage account configurations
source_config=$(az storage account show --resource-group $source_resource_group --name $source_storage_account)

# Extract relevant properties
account_kind=$(echo $source_config | jq -r '.kind')
account_tier=$(echo $source_config | jq -r '.sku.tier')
account_access_tier=$(echo $source_config | jq -r '.accessTier')

# Create target storage account with the same configurations
az storage account create --resource-group $target_resource_group --name $target_storage_account --sku $account_tier --kind $account_kind --location $target_location --access-tier $account_access_tier

# Get the source storage connection string
connection_string=$(az storage account show-connection-string --resource-group $target_resource_group --name $target_storage_account --output tsv)

# Generate a Shared Access Signtature for the account
end=$(date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ')
sas_token=$(az storage account generate-sas --connection-string "$connection_string" --expiry $end --https-only --permissions acwudt --resource-types co --services bfqt --output tsv)

# Use azcopy to copy contents from source to target storage account
azcopy copy "https://$source_storage_account.blob.core.windows.net/$sas_token" "https://$target_storage_account.blob.core.windows.net/" --recursive


echo "Storage account replication completed."