variable "group_owners" {
  description = "List of object IDs to set as owners of Entra ID groups"
  type        = list(string)
}

variable "subscription_workload_prod" {
  description = "Subscription ID for Workload-Prod"
  type        = string
}

variable "subscription_workload_nonprod" {
  description = "Subscription ID for Workload-NonProd"
  type        = string
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
