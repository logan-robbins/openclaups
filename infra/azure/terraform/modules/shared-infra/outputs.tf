output "location" {
  value = azurerm_resource_group.this.location
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_id" {
  value = azurerm_subnet.this.id
}

output "network_security_group_id" {
  value = azurerm_network_security_group.this.id
}
