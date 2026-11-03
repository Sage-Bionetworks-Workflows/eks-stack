# Spacelift space holding the MWAA stack
resource "spacelift_space" "mwaa-space" {
  name             = var.space_name
  parent_space_id  = var.parent_space_id
  description      = "Contains the managed Airflow resources for the DPE team."
  inherit_entities = true
}

# Runs the Terraform code in project_root, from the tracked branch of this repo
resource "spacelift_stack" "mwaa-stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  depends_on = [
    spacelift_space.mwaa-space
  ]

  administrative        = false
  autodeploy            = false
  protect_from_deletion = true
  # A pull request's proposed run can be promoted to apply the branch to dev. Prod only
  # applies commits on the tracked branch
  allow_run_promotion     = var.deployment_environment != "prod"
  branch                  = var.git_branch
  description             = "Creates an Amazon MWAA (Managed Airflow) environment"
  name                    = var.mwaa_stack_name
  project_root            = var.mwaa_stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.mwaa-space.id
  # The files outside project_root that its plan reads
  additional_project_globs = [
    "deployments/config/*.tf",
    "modules/mwaa/*.tf",
  ]
}

# The stack's only input. Every other value is in deployments/stacks/mwaa/environments.tf
resource "spacelift_environment_variable" "mwaa-stack-environment-variables" {
  for_each = {
    deployment_environment = var.deployment_environment
  }

  stack_id   = spacelift_stack.mwaa-stack.id
  name       = "TF_VAR_${each.key}"
  value      = each.value
  write_only = false
}

# Gives the stack read and write credentials for the AWS account it deploys to
resource "spacelift_aws_integration_attachment" "mwaa-aws-integration-attachment" {
  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.mwaa-stack.id
  read           = true
  write          = true
}
