resource "shoreline_notebook" "azure_storage_account_cross_region_replication_failures" {
  name       = "azure_storage_account_cross_region_replication_failures"
  data       = file("${path.module}/data/azure_storage_account_cross_region_replication_failures.json")
  depends_on = [shoreline_action.invoke_check_storage_replication,shoreline_action.invoke_storage_replication]
}

resource "shoreline_file" "check_storage_replication" {
  name             = "check_storage_replication"
  input_file       = "${path.module}/data/check_storage_replication.sh"
  md5              = filemd5("${path.module}/data/check_storage_replication.sh")
  description      = "Check if the storage account is in a region that supports the desired replication settings"
  destination_path = "/tmp/check_storage_replication.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "storage_replication" {
  name             = "storage_replication"
  input_file       = "${path.module}/data/storage_replication.sh"
  md5              = filemd5("${path.module}/data/storage_replication.sh")
  description      = "Replicate the storage account to another region"
  destination_path = "/tmp/storage_replication.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_check_storage_replication" {
  name        = "invoke_check_storage_replication"
  description = "Check if the storage account is in a region that supports the desired replication settings"
  command     = "`chmod +x /tmp/check_storage_replication.sh && /tmp/check_storage_replication.sh`"
  params      = ["REGION_NAME"]
  file_deps   = ["check_storage_replication"]
  enabled     = true
  depends_on  = [shoreline_file.check_storage_replication]
}

resource "shoreline_action" "invoke_storage_replication" {
  name        = "invoke_storage_replication"
  description = "Replicate the storage account to another region"
  command     = "`chmod +x /tmp/storage_replication.sh && /tmp/storage_replication.sh`"
  params      = ["TARGET_STORAGE_ACCOUNT_NAME","TARGET_RESOURCE_GROUP","TARGET_STORAGE_ACCOUNT_REGION","RESOURCE_GROUP_NAME","STORAGE_ACCOUNT_NAME"]
  file_deps   = ["storage_replication"]
  enabled     = true
  depends_on  = [shoreline_file.storage_replication]
}

