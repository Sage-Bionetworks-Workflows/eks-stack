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

  auth0_stack_name         = "DPE DEV Auth0"
  auth0_stack_project_root = "deployments/stacks/dpe-auth0"
  auth0_domain             = "dev-sage-dpe.us.auth0.com"
  auth0_clients = [
    {
      name        = "bfauble - automation"
      description = "App for testing signoz"
      app_type    = "non_interactive"
      scopes      = ["write:telemetry"]
    },
    {
      name        = "schematic - Github Actions"
      description = "Client for Github Actions to export telemetry data"
      app_type    = "non_interactive"
      scopes      = ["write:telemetry"]
    },
    {
      name        = "schematic - Dev"
      description = "Client for schematic deployed to AWS DEV to export telemetry data"
      app_type    = "non_interactive"
      scopes      = ["write:telemetry"]
    },
  ]
  auth0_identifier = "https://dev.sagedpe.org"

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
  auth0_jwks_uri         = "https://dev-sage-dpe.us.auth0.com/.well-known/jwks.json"
  deploy_auth0           = true

  ses_email_identities = ["aws-dpe-dev@sagebase.org"]
  # Defines the email address that will be used as the sender of the email alerts
  smtp_from = "aws-dpe-dev@sagebase.org"
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

  auth0_stack_name         = "DPE Auth0"
  auth0_stack_project_root = "deployments/stacks/dpe-auth0"
  auth0_domain             = ""
  auth0_clients            = []

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

  enable_cluster_ingress = false
  enable_otel_ingress    = false
  ssl_hostname           = ""
  auth0_jwks_uri         = ""
  deploy_auth0           = false

  ses_email_identities = []
}
