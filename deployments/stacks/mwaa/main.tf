module "mwaa" {
  source     = "../../../modules/mwaa"
  enabled    = var.enabled
  name       = var.name
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  tags = {
    Purpose    = "Managed Airflow for DPE workflows"
    ManagedBy  = "Terraform"
    CostCenter = "No Program / 000000"
  }
}
