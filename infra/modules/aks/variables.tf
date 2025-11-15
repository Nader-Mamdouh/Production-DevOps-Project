# Name of the cluster / resource prefix
variable "name" {
  description = "The name prefix for all resources in this module"
  type        = string
}

# Azure region to deploy the cluster
variable "location" {
  description = "The Azure region for resources"
  type        = string
}

# Number of nodes in the default node pool
variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

# VM size of each node in the default node pool
variable "node_type" {
  description = "Azure VM size for each node"
  type        = string
  default     = "Standard_B2s"
}
