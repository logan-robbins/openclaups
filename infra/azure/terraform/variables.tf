variable "environment_name" {
  description = "Logical environment name used for tagging and command targeting."
  type        = string
}

variable "fleet_manifest_path" {
  description = "Path to the fleet manifest YAML file, relative to the Terraform root."
  type        = string
}

variable "resource_tags" {
  description = "Additional tags merged onto every managed Azure resource."
  type        = map(string)
  default     = {}
}

variable "claw_secrets" {
  description = "Sensitive per-claw secrets keyed by claw name."
  type = map(object({
    telegram_bot_token   = string
    xai_api_key          = optional(string, "")
    openai_api_key       = optional(string, "")
    anthropic_api_key    = optional(string, "")
    brightdata_api_token = optional(string, "")
    tailscale_authkey    = optional(string, "")
  }))
  sensitive = true
  default   = {}
}
