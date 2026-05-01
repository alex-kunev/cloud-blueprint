variable "name"           { type = string }
variable "resource_group" { type = string }
variable "location"       { type = string }
variable "subnet_id"      { type = string }
variable "tags"           { type = map(string) }

resource "azurerm_cosmosdb_account" "this" {
  name                = "cosmos-${var.name}"
  resource_group_name = var.resource_group
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  tags                = var.tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Serverless — pay per request, near-zero cost at idle
  capabilities {
    name = "EnableServerless"
  }

  # Restrict access to the app subnet
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = var.subnet_id
  }
}

output "account_name" { value = azurerm_cosmosdb_account.this.name }
output "id"           { value = azurerm_cosmosdb_account.this.id }

output "primary_connection_string" {
  value     = azurerm_cosmosdb_account.this.primary_sql_connection_string
  sensitive = true
}
