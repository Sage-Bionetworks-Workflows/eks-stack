resource "spacelift_stack" "root_administrative_stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative    = true
  autodeploy        = false
  branch            = "ibcdpe-935-vpc-updates"
  description       = "Manages other spacelift resources"
  name              = "Root Spacelift Administrative Stack"
  project_root      = "environments"
  repository        = "eks-stack"
  terraform_version = "1.5.7"
  space_id          = "root"
}

resource "spacelift_space" "environment" {
  name            = "environment"
  parent_space_id = "root"
  description     = "Contains all the resources to deploy out to each enviornment."
}

module "terraform-registry" {
  source = "../modules"
}

module "common" {
  source = "./common"
}

module "dev-resources" {
  source = "./dev"
  depends_on = [
    module.common,
    module.terraform-registry,
  ]
  parent_space_id = spacelift_space.environment.id
}
