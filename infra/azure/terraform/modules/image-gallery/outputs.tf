output "gallery_name" {
  value = azurerm_shared_image_gallery.this.name
}

output "gallery_id" {
  value = azurerm_shared_image_gallery.this.id
}

output "image_definition_name" {
  value = azurerm_shared_image.this.name
}

output "image_definition_id" {
  value = azurerm_shared_image.this.id
}
