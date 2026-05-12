variable "name"           { type = string }
variable "resource_group" { type = string }
variable "location"       { type = string }
variable "subnet_id"      { type = string }
variable "key_vault_id"   { type = string }
variable "tags"           { type = map(string) }

locals {
  # Storage account names: max 24 chars, lowercase alphanumeric only
  storage_name = substr(replace("stfn${var.name}", "-", ""), 0, 24)
}

resource "azurerm_storage_account" "fn" {
  name                     = local.storage_name
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name}-fn"
  resource_group_name = var.resource_group
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                       = "func-${var.name}"
  resource_group_name        = var.resource_group
  location                   = var.location
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = azurerm_storage_account.fn.name
  storage_account_access_key = azurerm_storage_account.fn.primary_access_key
  virtual_network_subnet_id  = var.subnet_id
  https_only                 = true
  tags                       = var.tags

  identity { type = "SystemAssigned" }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
}

resource "azurerm_key_vault_access_policy" "fn" {
  key_vault_id       = var.key_vault_id
  tenant_id          = azurerm_linux_function_app.this.identity[0].tenant_id
  object_id          = azurerm_linux_function_app.this.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}

output "function_app_hostname" { value = azurerm_linux_function_app.this.default_hostname }
output "principal_id"          { value = azurerm_linux_function_app.this.identity[0].principal_id }
