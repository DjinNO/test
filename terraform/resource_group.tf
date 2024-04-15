resource "random_pet" "resource_group" {
  prefix = "example"
}

resource "azurerm_resource_group" "example" {
  name     = random_pet.resource_group.id
  location = var.location
}
