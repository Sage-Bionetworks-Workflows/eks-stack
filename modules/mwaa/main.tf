# The bucket name matches the one cloudposse/mwaa/aws generates (<name>-s3). It is built
# from var.name rather than read from the module output, which would create a cycle
data "aws_s3_object" "requirements" {
  count = var.enabled && var.requirements_s3_path != "" ? 1 : 0

  bucket = "${var.name}-s3"
  key    = var.requirements_s3_path
}

module "mwaa" {
  source  = "cloudposse/mwaa/aws"
  version = "0.16.0"

  enabled = var.enabled

  name       = var.name
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  airflow_version = var.airflow_version

  # Always the latest version of the file in the bucket, so uploading a new requirements
  # file and re-running the stack is enough to install it
  requirements_s3_path           = var.requirements_s3_path != "" ? var.requirements_s3_path : null
  requirements_s3_object_version = one(data.aws_s3_object.requirements[*].version_id)

  # All log groups are disabled upstream by default. The requirements install output is
  # written to the scheduler and worker logs
  scheduler_logs_enabled = true
  worker_logs_enabled    = true
  task_logs_enabled      = true

  # Workers finish running tasks (up to 12 hours) before being replaced on update.
  # Must be set: the upstream variable validation fails under OpenTofu when it is null.
  worker_replacement_strategy = "GRACEFUL"

  tags = var.tags
}
