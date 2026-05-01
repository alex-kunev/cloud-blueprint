variable "name"           { type = string }
variable "resource_group" { type = string }
variable "location"       { type = string }
variable "tags"           { type = map(string) }

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  resource_group_name = var.resource_group
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]

  # Required for App Service VNet integration
  delegation {
    name = "app-service"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  # Required for Cosmos DB VNet rules
  service_endpoints = ["Microsoft.AzureCosmosDB", "Microsoft.KeyVault"]
}

output "app_subnet_id" { value = azurerm_subnet.app.id }
output "vnet_id"       { value = azurerm_virtual_network.this.id }
