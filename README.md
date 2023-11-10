
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Azure Storage Account Cross-Region Replication Failures

This incident type involves failures related to cross-region replication of data in an Azure storage account. The issue arises when the replication settings are not working as expected due to various reasons such as region limitations, feature conflicts, storage account type, and access tier limitations. The incident requires troubleshooting and resolution of the underlying issue to ensure proper replication of data across different regions.

### Parameters

```shell
export RESOURCE_GROUP_NAME="PLACEHOLDER"
export STORAGE_ACCOUNT_NAME="PLACEHOLDER"
export REGION_NAME="PLACEHOLDER"
export TARGET_RESOURCE_GROUP="PLACEHOLDER"
export TARGET_STORAGE_ACCOUNT_NAME="PLACEHOLDER"
export TARGET_STORAGE_ACCOUNT_REGION="PLACEHOLDER"
```

## Debug

### List all the storage accounts in the selected subscription

```shell
az storage account list --resource-group ${RESOURCE_GROUP_NAME}
```

### Get the replication properties of a specific storage account

```shell
az storage account show --name ${STORAGE_ACCOUNT_NAME} --resource-group ${RESOURCE_GROUP_NAME} --expand geoReplicationStats
```

### Check if the storage account is in a region that supports the desired replication settings

```shell
# For example, check if the storage account supports zone-redundant replication (ZRS)
az account list-locations --query "[?name == '${REGION_NAME}'].availabilityZoneMappings"
```

### Get the paired region name for the current storage account region

```shell
az account list-locations --query "[?name == '${REGION_NAME}'].metadata.pairedRegion[0].name" --output tsv
```

### Check if the storage account type supports the desired replication settings

```shell
az storage account show --name ${STORAGE_ACCOUNT_NAME} --resource-group ${RESOURCE_GROUP_NAME} --query 'kind'
```

### Check if the access tier supports the desired replication settings

```shell
az storage account show --name ${STORAGE_ACCOUNT_NAME} --resource-group ${RESOURCE_GROUP_NAME} --query 'accessTier'
```

## Repair

### Replicate the storage account to another region

```shell
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
```