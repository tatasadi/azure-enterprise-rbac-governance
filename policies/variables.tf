variable "deny_owner_effect" {
  description = "Effect for deny owner policy (Audit, Deny, or Disabled). Start with Audit, then move to Deny after validation."
  type        = string
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.deny_owner_effect)
    error_message = "Effect must be Audit, Deny, or Disabled."
  }
}

variable "require_tags_effect" {
  description = "Effect for require tags policy (Audit or Deny). Start with Audit, then move to Deny after validation."
  type        = string
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.require_tags_effect)
    error_message = "Effect must be Audit, Deny, or Disabled."
  }
}
