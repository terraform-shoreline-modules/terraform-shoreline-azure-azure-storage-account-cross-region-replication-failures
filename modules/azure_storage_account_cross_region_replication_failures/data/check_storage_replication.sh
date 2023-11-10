# For example, check if the storage account supports zone-redundant replication (ZRS)
az account list-locations --query "[?name == '${REGION_NAME}'].availabilityZoneMappings"