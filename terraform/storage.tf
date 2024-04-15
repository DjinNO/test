resource "random_id" "front_door_endpoint_name" {
  byte_length = 8
}

resource "azurerm_storage_account" "example" {
  name                     = substr("examplestg${random_id.front_door_endpoint_name.hex}", 0, 24)
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  name                  = "static"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}
