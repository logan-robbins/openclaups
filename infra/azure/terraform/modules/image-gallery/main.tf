resource "azurerm_shared_image_gallery" "this" {
  name                = var.gallery_name
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "OpenClawps image gallery"
  tags                = var.tags
}

resource "azurerm_shared_image" "this" {
  name                = var.image_definition_name
  gallery_name        = azurerm_shared_image_gallery.this.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  hyper_v_generation  = var.hyper_v_generation

  identifier {
    publisher = var.image_identifier.publisher
    offer     = var.image_identifier.offer
    sku       = var.image_identifier.sku
  }

  trusted_launch_enabled = var.trusted_launch_enabled
  tags                   = var.tags
}
