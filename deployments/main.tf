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
  source          = "./spacelift/dpe-k8s"
  parent_space_id = spacelift_space.development.id
  admin_stack_id  = var.admin_stack_id

  aws_integration_id = var.org_sagebase_dnt_dev_aws_integration_id
  auto_deploy        = true
  git_branch         = var.git_branch

  space_name = "dpe-sandbox"

  k8s_stack_name         = "DPE DEV Kubernetes Infrastructure"
  k8s_stack_project_root = "deployments/stacks/dpe-k8s"

  k8s_stack_deployments_name         = "DPE DEV Kubernetes Deployments"
  k8s_stack_deployments_project_root = "dev/stacks/dpe-k8s-deployments"

  aws_account_id = "631692904429"
  region         = "us-east-1"

  cluster_name = "dpe-k8-sandbox"
  vpc_name     = "dpe-sandbox"

  vpc_cidr_block       = "10.51.0.0/16"
  public_subnet_cidrs  = ["10.51.1.0/24", "10.51.2.0/24", "10.51.3.0/24"]
  private_subnet_cidrs = ["10.51.4.0/24", "10.51.5.0/24", "10.51.6.0/24"]
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# TODO: Fill this out with production specific values when we are ready

# module "dpe-sandbox-spacelift-development" {
#   source          = "./spacelift/dpe-k8s"
#   parent_space_id = spacelift_space.development.id
#   admin_stack_id  = var.admin_stack_id

#   aws_integration_id = var.org_sagebase_dnt_dev_aws_integration_id
#   auto_deploy        = true
#   git_branch         = var.git_branch

#   space_name = "dpe-sandbox"

#   k8s_stack_name         = "DPE DEV Kubernetes Infrastructure"
#   k8s_stack_project_root = "deployments/stacks/dpe-k8s"

#   k8s_stack_deployments_name         = "DPE DEV Kubernetes Deployments"
#   k8s_stack_deployments_project_root = "dev/stacks/dpe-k8s-deployments"

#   aws_account_id = "631692904429"
#   region         = "us-east-1"

#   cluster_name = "dpe-k8-sandbox"
#   vpc_name     = "dpe-sandbox"

#   vpc_cidr_block       = "10.51.0.0/16"
#   public_subnet_cidrs  = ["10.51.1.0/24", "10.51.2.0/24", "10.51.3.0/24"]
#   private_subnet_cidrs = ["10.51.4.0/24", "10.51.5.0/24", "10.51.6.0/24"]
#   azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
# }