# The bucket name matches the one cloudposse/mwaa/aws generates (<name>-s3). It is built
# from var.name rather than read from the module output, which would create a cycle
data "aws_s3_object" "requirements" {
  count = var.enabled && var.requirements_s3_path != "" ? 1 : 0

  bucket = "${var.name}-s3"
  key    = var.requirements_s3_path
}

# Account ID for the Secrets Manager ARNs below
data "aws_caller_identity" "current" {}

locals {
  secrets_connections_prefix = "airflow/connections"
  secrets_variables_prefix   = "airflow/variables"
}

# Lets the execution role read Airflow connections and variables from Secrets Manager
data "aws_iam_policy_document" "secrets" {
  statement {
    sid     = "AirflowSecretsRead"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${local.secrets_connections_prefix}/*",
      "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${local.secrets_variables_prefix}/*",
    ]
  }

  statement {
    sid       = "AirflowSecretsList"
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }
}

# The MWAA environment, plus the S3 bucket, execution role and security group the upstream
# module creates for it
module "mwaa" {
  source  = "cloudposse/mwaa/aws"
  version = "0.16.0"

  enabled = var.enabled

  name       = var.name
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  airflow_version = var.airflow_version

  # Dev has no VPN or bastion into the VPC, so the UI must be public to be reachable.
  # Login is still IAM-only
  webserver_access_mode = "PUBLIC_ONLY"

  # Always the latest version of the file in the bucket, so uploading a new requirements
  # file and re-running the stack is enough to install it
  requirements_s3_path           = var.requirements_s3_path != "" ? var.requirements_s3_path : null
  requirements_s3_object_version = one(data.aws_s3_object.requirements[*].version_id)

  # All log groups are disabled upstream by default. The requirements install output is
  # written to the scheduler and worker logs
  scheduler_logs_enabled = true
  worker_logs_enabled    = true
  task_logs_enabled      = true

  # Connections and Variables are looked up in Secrets Manager first, then the metadata database
  airflow_configuration_options = {
    "secrets.backend" = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
    "secrets.backend_kwargs" = jsonencode({
      connections_prefix = local.secrets_connections_prefix
      variables_prefix   = local.secrets_variables_prefix
    })
  }
  additionals_policy_documents = [data.aws_iam_policy_document.secrets.json]

  # Workers finish running tasks (up to 12 hours) before being replaced on update.
  # Must be set: the upstream variable validation fails under OpenTofu when it is null.
  worker_replacement_strategy = "GRACEFUL"

  tags = var.tags
}
