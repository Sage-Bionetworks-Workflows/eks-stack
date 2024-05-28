resource "spacelift_stack" "root_administrative_stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }
  
  administrative    = true
  autodeploy        = false
  branch            = "main"
  description       = "Manages other spacelift resources"
  name              = "Root Spacelift Administrative Stack"
  project_root      = "spacelift"
  repository        = "eks-stack"
  terraform_version = "1.5.7"
  space_id          = "root"
}

module "policies" {
  source = "./modules/policies"
}

module "policy-attachments" {
  source = "./modules/policy-attachments"
  depends_on = [
    module.policies
  ]
}

module "stacks" {
  source = "./modules/stacks"
}