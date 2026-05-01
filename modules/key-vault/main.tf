variable "name"           { type = string }
variable "resource_group" { type = string }
variable "location"       { type = string }
variable "subnet_id"      { type = string }
variable "tags"           { type = map(string) }
variable "provisioner_ip" {
  type    = string
  default = ""
}

data "azurerm_client_config" "current" {}

locals {
  # Key Vault names: max 24 chars, alphanumeric + hyphens only
  kv_name = "kv-${substr(replace(var.name, "-", ""), 0, 21)}"
}

resource "azurerm_key_vault" "this" {
  name                       = local.kv_name
  resource_group_name        = var.resource_group
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  # Set to false for personal subs — makes teardown easier
  purge_protection_enabled = false
  tags                     = var.tags

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [var.subnet_id]
    ip_rules                   = var.provisioner_ip != "" ? [var.provisioner_ip] : []
  }
}

# Grants the Terraform service principal rights to write secrets during provisioning
resource "azurerm_key_vault_access_policy" "provisioner" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
}

output "id" { value = azurerm_key_vault.this.id }
