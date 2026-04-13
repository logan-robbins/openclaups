variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "gallery_name" {
  type = string
}

variable "image_definition_name" {
  type = string
}

variable "image_identifier" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
  })
}

variable "hyper_v_generation" {
  type    = string
  default = "V2"
}

variable "trusted_launch_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
