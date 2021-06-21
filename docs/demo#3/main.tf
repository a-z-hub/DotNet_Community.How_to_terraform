/////////////////////////////////////////////////////////////////

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

/////////////////////////////////////////////////////////////////

resource "random_password" "mssql_server_login_password" {
  length           = 32
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#%&?"
}

/////////////////////////////////////////////////////////////////

data "azurerm_client_config" "current" {}

/////////////////////////////////////////////////////////////////

variable "stage" {
  type = string

  validation {
    condition     = var.stage == "dev" || var.stage == "prod"
    error_message = "Only dev/prod allowed."
  }
}

variable "ver" {
  type = string

  validation {
    condition     = length(regex("v[0-9]+.[0-9]+.[0-9]+", var.ver)) > 0
    error_message = "Invalid version, use pattern 'vX.X.X' where 'X' is one+ number."
  }
}

variable "tags" {
  type = map(string)
  default = {
    "author" = "developer",
    "type"   = "demo"
    "team"   = "undefined"
  }

  validation {
    condition     = length(var.tags) > 0
    error_message = "Empty list of tags."
  }
}

/////////////////////////////////////////////////////////////////

locals {
  location                         = "westeurope"
  prefix                           = format("dot-net-community-tf-%s", var.stage)
  resource_group_name              = format("%s-rg", local.prefix)
  app_service_plan_name            = format("%s-plan", local.prefix)
  front_app_service_name           = format("%s-front-app", local.prefix)
  back_app_service_name            = format("%s-back-app", local.prefix)
  mssql_server_name                = format("%s-sql", local.prefix)
  mssql_database_name              = format("%s-sqldb", local.prefix)
  key_vault_name                   = format("%skv", replace(local.prefix, "-", ""))
  mssql_server_login               = "sa_account"
  mssql_firewall_rule_name         = "allow_access_to_resources_and_services"
  front_app_service_url            = format("https://%s", azurerm_app_service.front_app_service.default_site_hostname)
  back_app_service_url             = format("https://%s.azurewebsites.net", local.back_app_service_name)
  mssql_server_login_password      = random_password.mssql_server_login_password.result
  mssql_database_connection_string = "Server=${azurerm_mssql_server.mssql_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.mssql_database.name};User Id=${local.mssql_server_login};Password=${local.mssql_server_login_password};"
  tags                             = merge(var.tags, { "stage" = var.stage }, { "version" = var.ver })
}

/////////////////////////////////////////////////////////////////

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = local.app_service_plan_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku {
    tier = "Standard"
    size = "S1"
  }
  tags = local.tags
}

resource "azurerm_app_service" "front_app_service" {
  name                = local.front_app_service_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "API_URL" : local.back_app_service_url
  }
  tags = local.tags
}

resource "azurerm_app_service" "back_app_service" {
  name                = local.back_app_service_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "AllowedOrigins" : local.front_app_service_url
  }
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

resource "azurerm_mssql_server" "mssql_server" {
  name                         = local.mssql_server_name
  location                     = azurerm_resource_group.resource_group.location
  resource_group_name          = azurerm_resource_group.resource_group.name
  version                      = "12.0"
  administrator_login          = local.mssql_server_login
  administrator_login_password = local.mssql_server_login_password
  tags                         = local.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services_and_resources_access_to_server" {
  name             = local.mssql_firewall_rule_name
  server_id        = azurerm_mssql_server.mssql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "mssql_database" {
  name      = local.mssql_database_name
  server_id = azurerm_mssql_server.mssql_server.id
  tags      = local.tags
}

resource "azurerm_key_vault" "key_vault" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags
}

resource "azurerm_key_vault_access_policy" "cli_key_vault_access_policy" {
  key_vault_id       = azurerm_key_vault.key_vault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
}

resource "azurerm_key_vault_access_policy" "back_end_key_vault_access_policy" {
  key_vault_id       = azurerm_key_vault.key_vault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_app_service.back_app_service.identity.0.principal_id
  secret_permissions = ["get"]
  depends_on = [
    azurerm_key_vault_access_policy.cli_key_vault_access_policy
  ]
}

resource "azurerm_key_vault_secret" "mssql_database_connection_string_key_vault_secret" {
  key_vault_id = azurerm_key_vault.key_vault.id
  name         = "MSSQLDatabaseConnectionString"
  value        = local.mssql_database_connection_string
  tags         = local.tags
}

/////////////////////////////////////////////////////////////////

output "mssql_database_connection_string" {
  value     = local.mssql_database_connection_string
  sensitive = true
}

output "front_hostname" {
  value = azurerm_app_service.front_app_service.default_site_hostname
}

output "back_hostname" {
  value = azurerm_app_service.back_app_service.default_site_hostname
}

output "mssql_database_sku_name" {
  value = azurerm_mssql_database.mssql_database.sku_name
}

output "mssql_database_price" {
  value = "${azurerm_mssql_database.mssql_database.sku_name}, monthly cost: 371.87$"
}