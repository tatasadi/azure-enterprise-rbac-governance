variable "subscription_platform_connectivity" {
  description = "Subscription ID for Platform-Connectivity"
  type        = string
}

variable "subscription_platform_identity" {
  description = "Subscription ID for Platform-Identity"
  type        = string
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
