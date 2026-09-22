module "mwaa" {
  source  = "cloudposse/mwaa/aws"
  version = "0.16.0"

  enabled = var.enabled

  name       = var.name
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Workers finish running tasks (up to 12 hours) before being replaced on update.
  # Must be set: the upstream variable validation fails under OpenTofu when it is null.
  worker_replacement_strategy = "GRACEFUL"

  tags = var.tags
}
