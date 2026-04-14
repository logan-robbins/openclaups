packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

# claw-desktop: Ubuntu 24.04 + xfce4 + lightdm + x11vnc + dummy driver
# Baked once, rarely changes. claw-os builds on top of this.

source "azure-arm" "claw-desktop" {
  subscription_id    = var.subscription_id
  use_azure_cli_auth = true
  location           = var.location
  vm_size            = var.vm_size

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"

  shared_image_gallery_destination {
    gallery_name        = var.gallery_name
    image_name          = "claw-desktop"
    image_version       = var.image_version
    resource_group      = var.resource_group
    replication_regions = [var.location]
  }

  security_type       = "TrustedLaunch"
  secure_boot_enabled = true
  vtpm_enabled        = true
}

build {
  sources = ["source.azure-arm.claw-desktop"]

  # Desktop environment and display server only
  provisioner "shell" {
    scripts = [
      "../scripts/01-system-packages.sh",
      "../scripts/02-desktop-config.sh",
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }

  # Cleanup and generalize
  provisioner "shell" {
    script          = "../scripts/99-cleanup.sh"
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }
}
