module "aks" {
  source     = "../../modules/aks"
  name       = var.name
  location   = var.location
  node_count = var.node_count
  node_type  = var.node_type
}