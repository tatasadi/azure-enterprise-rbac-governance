variable "group_owners" {
  description = "List of object IDs to set as owners of Entra ID groups"
  type        = list(string)
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "Azure-RBAC-Governance"
    Environment = "Enterprise"
  }
}
