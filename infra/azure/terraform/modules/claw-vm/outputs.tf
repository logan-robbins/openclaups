output "public_ip_address" {
  value = azurerm_public_ip.this.ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}

output "data_disk_id" {
  value = azurerm_managed_disk.data.id
}
