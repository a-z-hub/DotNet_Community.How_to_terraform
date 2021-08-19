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
  features {}
}

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
  location              = "westeurope"
  prefix                = format("dot-net-community-tf-%s", var.stage)
  resource_group_name   = format("%s-rg", local.prefix)
  app_service_plan_name = format("%s-plan", local.prefix)
  back_app_service_name = format("%s-back-app", local.prefix)
  back_app_service_url  = format("https://%s.azurewebsites.net", local.back_app_service_name)
  tags                  = merge(var.tags, { "stage" = var.stage }, { "version" = var.ver })
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

resource "azurerm_app_service" "back_app_service" {
  name                = local.back_app_service_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

/////////////////////////////////////////////////////////////////

output "back_hostname" {
  value = azurerm_app_service.back_app_service.default_site_hostname
}
