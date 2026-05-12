variable "project_name" { type = string }
variable "environment"  { type = string }
variable "location" {
  type    = string
  default = "westeurope"
}
variable "owner"       { type = string }
variable "cost_center" { type = string }

locals {
  name = "${var.project_name}-${var.environment}"
  tags = {
    project     = var.project_name
    environment = var.environment
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "platform-provisioner"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

module "networking" {
  source         = "../../modules/networking"
  name           = local.name
  resource_group = azurerm_resource_group.this.name
  location       = var.location
  tags           = local.tags
}

module "key_vault" {
  source         = "../../modules/key-vault"
  name           = local.name
  resource_group = azurerm_resource_group.this.name
  location       = var.location
  subnet_id      = module.networking.app_subnet_id
  tags           = local.tags
}

module "function_app" {
  source         = "../../modules/function-app"
  name           = local.name
  resource_group = azurerm_resource_group.this.name
  location       = var.location
  subnet_id      = module.networking.app_subnet_id
  key_vault_id   = module.key_vault.id
  tags           = local.tags
}

output "function_app_hostname" { value = module.function_app.function_app_hostname }
output "principal_id"          { value = module.function_app.principal_id }
