locals {
  k8s_stack_environment_variables = {
    aws_account_id                         = var.aws_account_id
    region                                 = var.region
    pod_security_group_enforcing_mode      = var.pod_security_group_enforcing_mode
    cluster_name                           = var.cluster_name
    vpc_name                               = var.vpc_name
    vpc_cidr_block                         = var.vpc_cidr_block
    public_subnet_cidrs                    = var.public_subnet_cidrs
    private_subnet_cidrs_eks_control_plane = var.private_subnet_cidrs_eks_control_plane
    private_subnet_cidrs_eks_worker_nodes  = var.private_subnet_cidrs_eks_worker_nodes
    azs_eks_control_plane                  = var.azs_eks_control_plane
    azs_eks_worker_nodes                   = var.azs_eks_worker_nodes
    ses_email_identities                   = var.ses_email_identities
    ses_email_domains                      = var.ses_email_domains
  }

  k8s_stack_deployments_variables = {
    spotinst_account       = var.spotinst_account
    vpc_cidr_block         = var.vpc_cidr_block
    cluster_name           = var.cluster_name
    auto_deploy            = var.auto_deploy
    auto_prune             = var.auto_prune
    git_revision           = var.git_branch
    aws_account_id         = var.aws_account_id
    enable_cluster_ingress = var.enable_cluster_ingress
    enable_otel_ingress    = var.enable_otel_ingress
    ssl_hostname           = var.ssl_hostname
    auth0_jwks_uri         = var.auth0_jwks_uri
    smtp_from              = var.smtp_from
    smtp_password          = var.smtp_password
    smtp_user              = var.smtp_user
  }

  auth0_stack_variables = {
    cluster_name         = var.cluster_name
    auth0_domain         = var.auth0_domain
    auth0_clients        = var.auth0_clients
  }

  # Variables to be passed from the k8s stack to the deployments stack
  k8s_stack_to_deployment_variables = {
    vpc_id                              = "TF_VAR_vpc_id"
    private_subnet_ids_eks_worker_nodes = "TF_VAR_private_subnet_ids_eks_worker_nodes"
    node_security_group_id              = "TF_VAR_node_security_group_id"
    pod_to_node_dns_sg_id               = "TF_VAR_pod_to_node_dns_sg_id"
    smtp_username                       = "TF_VAR_smtp_username"
    smtp_password                       = "TF_VAR_smtp_password"
  }
}

resource "spacelift_space" "dpe-space" {
  name             = var.space_name
  parent_space_id  = var.parent_space_id
  description      = "Contains resources for the DPE team."
  inherit_entities = true
}

resource "spacelift_stack" "k8s-stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  depends_on = [
    spacelift_space.dpe-space
  ]

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Infrastructure to support deploying to an EKS cluster"
  name                    = var.k8s_stack_name
  project_root            = var.k8s_stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
  additional_project_globs = [
    "deployments/"
  ]
}

resource "spacelift_environment_variable" "k8s-stack-environment-variables" {
  for_each = local.k8s_stack_environment_variables

  stack_id   = spacelift_stack.k8s-stack.id
  name       = "TF_VAR_${each.key}"
  value      = try(tostring(each.value), jsonencode(each.value))
  write_only = false
}

resource "spacelift_stack" "k8s-stack-deployments" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  depends_on = [
    spacelift_space.dpe-space
  ]

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Deployments internal to an EKS cluster"
  name                    = var.k8s_stack_deployments_name
  project_root            = var.k8s_stack_deployments_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
  additional_project_globs = [
    "deployments/"
  ]
}

resource "spacelift_environment_variable" "k8s-stack-deployments-environment-variables" {
  for_each = local.k8s_stack_deployments_variables

  stack_id   = spacelift_stack.k8s-stack-deployments.id
  name       = "TF_VAR_${each.key}"
  value      = try(tostring(each.value), jsonencode(each.value))
  write_only = false
}


# TODO: There is some work here that is needed:
# 1) When we increment a module the admin stack needs to run and create the new resources/modules in spacelift
# 2) We need any stacks that are using that new resource/module then need to run
# The problem:
# When this dependent stack is run it might be "Skipped" because the admin stack does not have different values in the `output.tf` that is used here
# That means the child stack is never run.

# resource "spacelift_stack_dependency" "dependency-on-admin-stack" {
#   for_each = {
#     k8s-stack             = spacelift_stack.k8s-stack,
#     k8s-stack-deployments = spacelift_stack.k8s-stack-deployments
#   }

#   stack_id            = each.value.id
#   depends_on_stack_id = var.admin_stack_id
# }

resource "spacelift_context_attachment" "k8s-kubeconfig-hooks" {
  context_id = "kubernetes-deployments-kubeconfig"
  stack_id   = spacelift_stack.k8s-stack-deployments.id
}

resource "spacelift_stack_dependency" "k8s-stack-to-deployments" {
  stack_id            = spacelift_stack.k8s-stack-deployments.id
  depends_on_stack_id = spacelift_stack.k8s-stack.id
}

resource "spacelift_stack_dependency_reference" "dependency-references" {
  for_each = local.k8s_stack_to_deployment_variables

  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = each.key
  input_name          = each.value
  # See https://github.com/spacelift-io/terraform-provider-spacelift/issues/565
  trigger_always = true
}

resource "spacelift_stack_dependency_reference" "region-name" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "region"
  input_name          = "REGION"
}

resource "spacelift_stack_dependency_reference" "cluster-name" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "cluster_name"
  input_name          = "CLUSTER_NAME"
}

# resource "spacelift_policy_attachment" "policy-attachment" {
#   policy_id = each.value.policy_id
#   stack_id  = spacelift_stack.k8s-stack.id
# }

resource "spacelift_stack_destructor" "k8s-stack-deployments-destructor" {
  depends_on = [
    spacelift_stack.k8s-stack,
    spacelift_aws_integration_attachment.k8s-deployments-aws-integration-attachment,
    spacelift_context_attachment.k8s-kubeconfig-hooks,
    spacelift_stack_dependency_reference.cluster-name,
    spacelift_stack_dependency_reference.region-name,
    spacelift_environment_variable.k8s-stack-deployments-environment-variables
  ]

  stack_id = spacelift_stack.k8s-stack-deployments.id
}

resource "spacelift_stack_destructor" "k8s-stack-destructor" {
  depends_on = [
    spacelift_aws_integration_attachment.k8s-aws-integration-attachment,
    spacelift_context_attachment.k8s-kubeconfig-hooks,
    spacelift_stack_dependency_reference.cluster-name,
    spacelift_stack_dependency_reference.region-name,
    spacelift_environment_variable.k8s-stack-environment-variables
  ]

  stack_id = spacelift_stack.k8s-stack.id
}

resource "spacelift_aws_integration_attachment" "k8s-aws-integration-attachment" {
  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.k8s-stack.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "k8s-deployments-aws-integration-attachment" {

  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.k8s-stack-deployments.id
  read           = true
  write          = true
}


resource "spacelift_stack" "auth0" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  depends_on = [
    spacelift_space.dpe-space
  ]

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Stack used to create and manage Auth0 for authentication"
  name                    = var.auth0_stack_name
  project_root            = var.auth0_stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
  additional_project_globs = [
    "deployments/"
  ]
}

resource "spacelift_stack_destructor" "auth0-stack-destructor" {
  stack_id = spacelift_stack.auth0.id
}


resource "spacelift_environment_variable" "auth0-stack-environment-variables" {
  for_each = local.auth0_stack_variables

  stack_id   = spacelift_stack.auth0.id
  name       = "TF_VAR_${each.key}"
  value      = try(tostring(each.value), jsonencode(each.value))
  write_only = false
}