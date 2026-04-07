variable "name"              { type = string }
variable "resource_group"    { type = string }
variable "location"          { type = string }
variable "sku"               { 
  type = string 
  default = "B2" 
  }
variable "subnet_id"         { type = string }
variable "key_vault_id"      { type = string }
variable "tags"              { type = map(string) }

resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name}"
  resource_group_name = var.resource_group
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                      = "app-${var.name}"
  resource_group_name       = var.resource_group
  location                  = var.location
  service_plan_id           = azurerm_service_plan.this.id
  virtual_network_subnet_id = var.subnet_id
  https_only                = true
  tags                      = var.tags

  identity { type = "SystemAssigned" }

  site_config {
    always_on         = true
    health_check_path = "/health"
  }
}

resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_linux_web_app.this.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.this.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}

output "app_hostname"    { value = azurerm_linux_web_app.this.default_hostname }
output "principal_id"   { value = azurerm_linux_web_app.this.identity[0].principal_id }