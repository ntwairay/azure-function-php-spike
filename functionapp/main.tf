provider "azurerm" {
  version = "~> 2.1.0"
  features {}
}

terraform {
  required_version = ">= 0.12.0"
}

resource "azurerm_resource_group" "funcapp" {
  name     = var.resource_group_name == "" ? replace(var.name, "/[^a-z0-9]/", "") : var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "funcapp" {
  name                      = var.storage_account_name == "" ? replace(var.name, "/[^a-z0-9]/", "") : var.storage_account_name
  resource_group_name       = azurerm_resource_group.funcapp.name
  location                  = azurerm_resource_group.funcapp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "funcapp" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.funcapp.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "funcapp" {
  name = "functionapp.zip"
  storage_account_name   = azurerm_storage_account.funcapp.name
  storage_container_name = azurerm_storage_container.funcapp.name
  type   = "Block"
  source = var.functionapp_path
}

resource "azurerm_app_service_plan" "funcapp" {
  name                = var.service_plan_name == "" ? replace(var.name, "/[^a-z0-9]/", "") : var.service_plan_name
  location            = azurerm_resource_group.funcapp.location
  resource_group_name = azurerm_resource_group.funcapp.name
  kind                = lower(var.plan_type) == "consumption" ? "FunctionApp" : var.plan_settings["kind"]

  sku {
    tier     = lower(var.plan_type) == "consumption" ? "Dynamic" : "Standard"
    size     = lower(var.plan_type) == "consumption" ? "Y1" : var.plan_settings["size"]
    capacity = lower(var.plan_type) == "consumption" ? 0 : var.plan_settings["capacity"]
  }
}

data "azurerm_storage_account_sas" "funcapp" {
  connection_string = "${azurerm_storage_account.funcapp.primary_connection_string}"
  https_only        = false
  resource_types {
    service   = true
    container = true
    object    = true
  }
  services {
    blob  = true
    queue = true
    table = true
    file  = false
  }
  start  = "2020-03-21"
  expiry = "2028-03-21"
  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
  }
}

resource "azurerm_function_app" "funcapp" {
  name                      = var.name
  location                  = azurerm_resource_group.funcapp.location
  resource_group_name       = azurerm_resource_group.funcapp.name
  app_service_plan_id       = azurerm_app_service_plan.funcapp.id
  storage_connection_string = azurerm_storage_account.funcapp.primary_connection_string
  client_affinity_enabled   = var.client_affinity_enabled
  version                   = var.func_version
  app_settings              = {
     FUNCTIONS_WORKER_RUNTIME = var.function_worker_runtime
     WEBSITE_RUN_FROM_ZIP     = "https://${azurerm_storage_account.funcapp.name}.blob.core.windows.net/function-releases/functionapp.zip"
     WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "https://${azurerm_storage_account.funcapp.name}.blob.core.windows.net/${azurerm_storage_container.funcapp.name}/${azurerm_storage_blob.funcapp.name}${data.azurerm_storage_account_sas.funcapp.sas}"
  }
}
