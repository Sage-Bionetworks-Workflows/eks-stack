module "mwaa" {
  source  = "cloudposse/mwaa/aws"
  version = "0.16.0"

  enabled = var.enabled

  name       = var.name
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  tags = var.tags
}
