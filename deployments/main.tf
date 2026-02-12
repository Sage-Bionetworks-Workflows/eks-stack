resource "spacelift_space" "development" {
  name             = "development"
  parent_space_id  = var.parent_space_id
  description      = "Contains all the resources to deploy out to the dev enviornment."
  inherit_entities = true
}

resource "spacelift_space" "staging" {
  name             = "staging"
  parent_space_id  = var.parent_space_id
  description      = "Contains all the resources to deploy out to the staging enviornment."
  inherit_entities = true
}

resource "spacelift_space" "production" {
  name             = "production"
  parent_space_id  = var.parent_space_id
  description      = "Contains all the resources to deploy out to the production enviornment."
  inherit_entities = true
}

module "dpe-sandbox-spacelift-development" {
  source           = "./spacelift/dpe-k8s"
  parent_space_id  = spacelift_space.development.id
  admin_stack_id   = var.admin_stack_id
  spotinst_account = "act-45de6f47"

  aws_integration_id = var.org_sagebase_dnt_dev_aws_integration_id
  auto_deploy        = false
  auto_prune         = true
  git_branch         = var.git_branch

  space_name = "dpe-sandbox"

  k8s_stack_name         = "DPE DEV Kubernetes Infrastructure"
  k8s_stack_project_root = "deployments/stacks/dpe-k8s"

  k8s_stack_deployments_name         = "DPE DEV Kubernetes Deployments"
  k8s_stack_deployments_project_root = "deployments/stacks/dpe-k8s-deployments"

  aws_account_id = "631692904429"
  region         = "us-east-1"

  cluster_name = "dpe-k8-sandbox"
  vpc_name     = "dpe-sandbox"

  vpc_cidr_block = "10.52.16.0/20"
  # A public subnet is required for each AZ in which the worker nodes are deployed
  public_subnet_cidrs                    = ["10.52.16.0/24", "10.52.17.0/24", "10.52.19.0/24"]
  private_subnet_cidrs_eks_control_plane = ["10.52.18.0/28", "10.52.18.16/28"]
  azs_eks_control_plane                  = ["us-east-1a", "us-east-1b"]

  private_subnet_cidrs_eks_worker_nodes = ["10.52.28.0/22", "10.52.24.0/22", "10.52.20.0/22"]
  azs_eks_worker_nodes                  = ["us-east-1c", "us-east-1b", "us-east-1a"]

  enable_cluster_ingress = true
  enable_otel_ingress    = true
  ssl_hostname           = "dev.sagedpe.org"
  ses_email_identities = ["aws-dpe-dev@sagebase.org"]
  # Defines the email address that will be used as the sender of the email alerts
  smtp_from = "aws-dpe-dev@sagebase.org"
}

module "dpe-sandbox-spacelift-staging" {
  source           = "./spacelift/dpe-k8s"
  parent_space_id  = spacelift_space.staging.id
  admin_stack_id   = var.admin_stack_id
  spotinst_account = "act-ac6522b4"

  aws_integration_id = var.org_sagebase_dpe_prod_aws_integration_id
  auto_deploy        = false
  git_branch         = var.git_branch

  space_name = "dpe-staging"

  k8s_stack_name         = "DPE Staging Kubernetes Infrastructure"
  k8s_stack_project_root = "deployments/stacks/dpe-k8s"

  k8s_stack_deployments_name         = "DPE Staging Kubernetes Deployments"
  k8s_stack_deployments_project_root = "deployments/stacks/dpe-k8s-deployments"

  aws_account_id = "766808016710"
  region         = "us-east-1"

  cluster_name = "dpe-k8-staging"
  vpc_name     = "dpe-k8-staging"

  vpc_cidr_block = "10.52.32.0/20"
  # A public subnet is required for each AZ in which the worker nodes are deployed
  public_subnet_cidrs                    = ["10.52.32.0/24", "10.52.33.0/24", "10.52.34.0/24"]
  private_subnet_cidrs_eks_control_plane = ["10.52.35.0/28", "10.52.35.16/28"]
  azs_eks_control_plane                  = ["us-east-1a", "us-east-1b"]

  private_subnet_cidrs_eks_worker_nodes = ["10.52.36.0/22", "10.52.40.0/22", "10.52.44.0/22"]
  azs_eks_worker_nodes                  = ["us-east-1c", "us-east-1b", "us-east-1a"]

  enable_cluster_ingress = true
  enable_otel_ingress    = true
  ssl_hostname           = "staging.sagedpe.org"
  ses_email_identities = []
  smtp_from            = ""
}

module "dpe-sandbox-spacelift-production" {
  source           = "./spacelift/dpe-k8s"
  parent_space_id  = spacelift_space.production.id
  admin_stack_id   = var.admin_stack_id
  spotinst_account = "act-ac6522b4"

  aws_integration_id = var.org_sagebase_dpe_prod_aws_integration_id
  auto_deploy        = false
  git_branch         = var.git_branch

  space_name = "dpe-k8s"

  k8s_stack_name         = "DPE Kubernetes Infrastructure"
  k8s_stack_project_root = "deployments/stacks/dpe-k8s"

  k8s_stack_deployments_name         = "DPE Kubernetes Deployments"
  k8s_stack_deployments_project_root = "deployments/stacks/dpe-k8s-deployments"

  aws_account_id = "766808016710"
  region         = "us-east-1"

  cluster_name = "dpe-k8"
  vpc_name     = "dpe-k8"

  vpc_cidr_block = "10.52.0.0/20"
  # A public subnet is required for each AZ in which the worker nodes are deployed
  public_subnet_cidrs                    = ["10.52.0.0/24", "10.52.1.0/24", "10.52.3.0/24"]
  private_subnet_cidrs_eks_control_plane = ["10.52.2.0/28", "10.52.2.16/28"]
  azs_eks_control_plane                  = ["us-east-1a", "us-east-1b"]

  private_subnet_cidrs_eks_worker_nodes = ["10.52.12.0/22", "10.52.8.0/22", "10.52.4.0/22"]
  azs_eks_worker_nodes                  = ["us-east-1c", "us-east-1b", "us-east-1a"]

  enable_cluster_ingress = true
  enable_otel_ingress    = true
  ssl_hostname           = "prod.sagedpe.org"
  ses_email_identities = ["dpe@sagebase.org"]
  # Defines the email address that will be used as the sender of the email alerts
  smtp_from = "dpe@sagebase.org"
}

module "snowflake-spacelift-development" {
  source = "./spacelift/snowflake"
  
  # Spacelift configuration
  aws_integration_id = var.org_sagebase_dnt_dev_aws_integration_id
  auto_deploy        = false
  git_branch         = var.git_branch
  parent_space_id    = spacelift_space.development.id
  space_name         = "snowflake-dev"

  # Snowflake stack deployment configuration
  snowflake_stack_name         = "Snowflake S3 Development"
  snowflake_stack_project_root = "deployments/stacks/snowflake"

  # AWS configuration
  aws_account_id         = "631692904429"
  region                 = "us-east-1"
  source_account_id      = "449435941126"
  source_bucket_arn      = "arn:aws:s3:::dev.dpe.rds.backups.sagebase.org"
  snowflake_bucket_name  = "snowflake-rds-landing-dev"
}

module "snowflake-spacelift-production" {
  source = "./spacelift/snowflake"
  
  # Spacelift configuration
  aws_integration_id     = var.org_sagebase_dpe_prod_aws_integration_id
  auto_deploy            = false
  git_branch             = var.git_branch
  parent_space_id        = spacelift_space.production.id
  space_name             = "snowflake-prod"

  # Snowflake stack deployment configuration
  snowflake_stack_name         = "Snowflake S3 Production"
  snowflake_stack_project_root = "deployments/stacks/snowflake"

  # AWS configuration
  aws_account_id         = "766808016710"
  region                 = "us-east-1"
  source_account_id      = "325565585839"
  source_bucket_arn      = "arn:aws:s3:::prod.dpe.rds.backups.sagebase.org"
  snowflake_bucket_name  = "snowflake-rds-landing-prod"
}
