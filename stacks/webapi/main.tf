data "azurerm_client_config" "current" {}
variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" {
  type    = string
  default = "westeurope"
}
variable "owner"        { type = string }
variable "cost_center"  { type = string }
variable "sku" {
  type    = string
  default = "B2"
}

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

module "cosmos" {
  source         = "../../modules/cosmos"
  name           = local.name
  resource_group = azurerm_resource_group.this.name
  location       = var.location
  subnet_id      = module.networking.app_subnet_id
  tags           = local.tags
}

# module "app_service" {
#   source         = "../../modules/app-service"
#   name           = local.name
#   resource_group = azurerm_resource_group.this.name
#   location       = var.location
#   subnet_id      = module.networking.app_subnet_id
#   key_vault_id   = module.key_vault.id
#   sku            = var.sku
#   tags           = local.tags
# }

# Wire Cosmos connection string into KV, give app access
resource "azurerm_key_vault_secret" "cosmos_conn" {
  name         = "cosmos-connection-string"
  value        = module.cosmos.primary_connection_string
  key_vault_id = module.key_vault.id
}

# resource "azurerm_cosmosdb_sql_role_assignment" "app" {
#   resource_group_name = azurerm_resource_group.this.name
#   account_name        = module.cosmos.account_name
#   role_definition_id  = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.DocumentDB/databaseAccounts/${module.cosmos.account_name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
#   principal_id        = module.app_service.principal_id
#   scope               = module.cosmos.id
# }