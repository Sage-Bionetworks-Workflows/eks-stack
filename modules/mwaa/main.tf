data "aws_caller_identity" "current" {}

locals {
  # Same prefixes as the EKS Airflow deployment (modules/apache-airflow) so secrets follow one
  # naming scheme
  secrets_connections_prefix = "airflow/connections"
  secrets_variables_prefix   = "airflow/variables"

  orca_recipes_url  = "https://raw.githubusercontent.com/Sage-Bionetworks-Workflows/orca-recipes/${var.orca_recipes_sha}"
  requirements_path = "requirements.txt"
  bucket_name       = trimprefix(module.mwaa.s3_bucket_arn, "arn:aws:s3:::")
}

# DAG dependencies live in orca-recipes. MWAA installs them with the constraints file from the
# same commit, since the upstream Airflow constraints cannot install synapseclient
data "http" "requirements" {
  count = var.enabled ? 1 : 0

  url = "${local.orca_recipes_url}/requirements-airflow.txt"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Could not download requirements-airflow.txt at orca-recipes commit ${var.orca_recipes_sha}"
    }
  }
}

resource "aws_s3_object" "requirements" {
  count = var.enabled ? 1 : 0

  bucket       = local.bucket_name
  key          = local.requirements_path
  content_type = "text/plain"
  content      = <<-EOT
    --constraint "${local.orca_recipes_url}/mwaa/constraints.txt"
    ${data.http.requirements[0].response_body}
  EOT

  tags = var.tags
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

  # A new object version, from a new orca_recipes_sha, makes MWAA install the requirements again
  requirements_s3_path           = local.requirements_path
  requirements_s3_object_version = one(aws_s3_object.requirements[*].version_id)

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
    # Read by DAGs as AIRFLOW__ORCA__ENVIRONMENT to choose dev or prod values
    "orca.environment" = var.deployment_environment
  }
  additionals_policy_documents = [data.aws_iam_policy_document.secrets.json]

  # Workers finish running tasks (up to 12 hours) before being replaced on update.
  # Must be set: the upstream variable validation fails under OpenTofu when it is null.
  worker_replacement_strategy = "GRACEFUL"

  tags = var.tags
}

# Lets the orca-recipes GitHub Actions deploy job for this environment replace the DAGs. Only
# jobs running in the matching GitHub environment, which only allows the main branch, can
# assume it
data "aws_iam_openid_connect_provider" "github" {
  count = var.enabled ? 1 : 0

  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "dag_deploy_trust" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Sage-Bionetworks-Workflows/orca-recipes:environment:mwaa-${var.deployment_environment}"]
    }
  }
}

# Only the dags/ prefix. requirements.txt is owned by this module
data "aws_iam_policy_document" "dag_deploy" {
  count = var.enabled ? 1 : 0

  statement {
    actions   = ["s3:ListBucket"]
    resources = [module.mwaa.s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["dags/*"]
    }
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.mwaa.s3_bucket_arn}/dags/*"]
  }
}

resource "aws_iam_role" "dag_deploy" {
  count = var.enabled ? 1 : 0

  name               = "${var.name}-dag-deploy"
  assume_role_policy = data.aws_iam_policy_document.dag_deploy_trust[0].json

  tags = var.tags
}

resource "aws_iam_role_policy" "dag_deploy" {
  count = var.enabled ? 1 : 0

  name   = "dag-deploy"
  role   = aws_iam_role.dag_deploy[0].id
  policy = data.aws_iam_policy_document.dag_deploy[0].json
}
