variable "management_group_prod" {
  description = "Management Group display name for Prod"
  type        = string
}

variable "management_group_nonprod" {
  description = "Management Group display name for NonProd"
  type        = string
}

variable "management_group_landing_zones" {
  description = "Management Group display name for LandingZones (parent of Prod/NonProd) - used for roles that need access to both"
  type        = string
  default     = "LandingZones"
}
