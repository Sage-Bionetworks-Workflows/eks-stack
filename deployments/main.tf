resource "spacelift_space" "development" {
  name             = "development"
  parent_space_id  = var.parent_space_id
  description      = "Contains all the resources to deploy out to the dev enviornment."
  inherit_entities = true
}

resource "spacelift_space" "production" {
  name             = "production"
  parent_space_id  = var.parent_space_id
  description      = "Contains all the resources to deploy out to the production enviornment."
  inherit_entities = true
}

# Managed Airflow (MWAA) environment for DPE workflows, in the DNT dev account. Its values
# are in deployments/stacks/mwaa/environments.tf
module "mwaa-spacelift-development" {
  source = "./spacelift/mwaa"

  aws_integration_id      = var.org_sagebase_dnt_dev_aws_integration_id
  git_branch              = var.git_branch
  parent_space_id         = spacelift_space.development.id
  space_name              = "mwaa-dev"
  mwaa_stack_name         = "DPE DEV Managed Airflow"
  mwaa_stack_project_root = "deployments/stacks/mwaa"
  deployment_environment  = "dev"
}

module "mwaa-spacelift-production" {
  source = "./spacelift/mwaa"

  aws_integration_id      = var.org_sagebase_dpe_prod_aws_integration_id
  git_branch              = var.git_branch
  parent_space_id         = spacelift_space.production.id
  space_name              = "mwaa-prod"
  mwaa_stack_name         = "DPE PROD Managed Airflow"
  mwaa_stack_project_root = "deployments/stacks/mwaa"
  deployment_environment  = "prod"
}

# S3 buckets the orca-recipes DAGs write to, in the DNT dev account. Its values are in
# deployments/stacks/dag-buckets/environments.tf and deployments/config
module "dag-buckets-spacelift-development" {
  source = "./spacelift/dag-buckets"

  aws_integration_id     = var.org_sagebase_dnt_dev_aws_integration_id
  git_branch             = var.git_branch
  space_id               = spacelift_space.development.id
  stack_name             = "DPE DEV DAG Buckets"
  deployment_environment = "dev"
}

module "dag-buckets-spacelift-production" {
  source = "./spacelift/dag-buckets"

  aws_integration_id     = var.org_sagebase_dpe_prod_aws_integration_id
  git_branch             = var.git_branch
  space_id               = spacelift_space.production.id
  stack_name             = "DPE PROD DAG Buckets"
  deployment_environment = "prod"
}

module "snowflake-spacelift-development" {
  source = "./spacelift/snowflake"

  # Spacelift configuration
  aws_integration_id = var.org_sagebase_dpe_prod_aws_integration_id
  git_branch         = var.git_branch
  parent_space_id    = spacelift_space.production.id
  space_name         = "synapse-dev-to-snowflake"

  # Snowflake stack deployment configuration
  snowflake_stack_name         = "Synapse Dev RDS Snapshots"
  snowflake_stack_project_root = "deployments/stacks/snowflake"

  # AWS configuration
  aws_account_id        = "766808016710"
  region                = "us-east-1"
  source_account_id     = "449435941126"
  source_bucket_arn     = "arn:aws:s3:::dev.dpe.rds.backups.sagebase.org"
  source_iam_role       = "dev-rds-repl-role"
  snowflake_bucket_name = "synapse-snowflake-rds-snapshots-dev"

  # Snowflake authentication
  snowflake_principal_arn = "arn:aws:iam::365909334157:user/m2nb0000-s"
  snowflake_external_id   = "UO70315_SFCRole=2_QYIb43i20hlGZ/yzhC8zoAzsE8E="
}

module "snowflake-spacelift-production" {
  source = "./spacelift/snowflake"

  # Spacelift configuration
  aws_integration_id = var.org_sagebase_dpe_prod_aws_integration_id
  git_branch         = var.git_branch
  parent_space_id    = spacelift_space.production.id
  space_name         = "synapse-prod-to-snowflake"

  # Snowflake stack deployment configuration
  snowflake_stack_name         = "Synapse Prod RDS Snapshots"
  snowflake_stack_project_root = "deployments/stacks/snowflake"

  # AWS configuration
  aws_account_id        = "766808016710"
  region                = "us-east-1"
  source_account_id     = "325565585839"
  source_bucket_arn     = "arn:aws:s3:::prod.dpe.rds.backups.sagebase.org"
  source_iam_role       = "prod-rds-repl-role"
  snowflake_bucket_name = "synapse-snowflake-rds-snapshots-prod"

  # Snowflake authentication
  snowflake_principal_arn = "arn:aws:iam::365909334157:user/m2nb0000-s"
  snowflake_external_id   = "UO70315_SFCRole=2_MrT3ubydhclba/9w8Kq1btbWsBc="
}
