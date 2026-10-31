# This config manages Spacelift pipelines for:
#   - deployments/stacks/dpe-k8s/              (VPC + EKS infrastructure)
#   - deployments/stacks/dpe-k8s-deployments/  (K8s-internal deployments)

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
  }

  k8s_stack_deployments_variables = {
    spotinst_account         = var.spotinst_account
    vpc_cidr_block           = var.vpc_cidr_block
    cluster_name             = var.cluster_name
    auto_deploy              = var.auto_deploy
    auto_prune               = var.auto_prune
    git_revision             = var.git_branch
    aws_account_id           = var.aws_account_id
    enable_cluster_ingress   = var.enable_cluster_ingress
    enable_otel_ingress      = var.enable_otel_ingress
    ssl_hostname             = var.ssl_hostname
    smtp_from                = var.smtp_from
    eks_min_ami_release_date = var.eks_min_ami_release_date
  }

  # Variables to be passed from the k8s stack to the deployments stack
  k8s_stack_to_deployment_variables = {
    vpc_id                              = "TF_VAR_vpc_id"
    private_subnet_ids_eks_worker_nodes = "TF_VAR_private_subnet_ids_eks_worker_nodes"
    node_security_group_id              = "TF_VAR_node_security_group_id"
    pod_to_node_dns_sg_id               = "TF_VAR_pod_to_node_dns_sg_id"
    smtp_user                           = "TF_VAR_smtp_user"
    smtp_password                       = "TF_VAR_smtp_password"
    cluster_oidc_provider_arn           = "TF_VAR_cluster_oidc_provider_arn"
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
  autodeploy              = false
  protect_from_deletion   = true
  branch                  = var.git_branch
  description             = "Infrastructure to support deploying to an EKS cluster"
  name                    = var.k8s_stack_name
  project_root            = var.k8s_stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
  # The files outside project_root that its plan reads
  additional_project_globs = [
    "modules/sage-aws-eks/*.tf",
    "modules/sage-aws-ses/*.tf",
    "modules/sage-aws-vpc/*.tf",
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
  autodeploy              = false
  protect_from_deletion   = true
  branch                  = var.git_branch
  description             = "Deployments internal to an EKS cluster"
  name                    = var.k8s_stack_deployments_name
  project_root            = var.k8s_stack_deployments_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
  # The files outside project_root that its plan reads. ArgoCD reads the other templates/ and
  # resources/ files from git, so changing them does not change this plan
  additional_project_globs = [
    "modules/apache-airflow/*.tf",
    "modules/argo-cd/*.tf",
    "modules/argo-cd/templates/values.yaml",
    "modules/cert-manager/*.tf",
    "modules/envoy-gateway/*.tf",
    "modules/flux-cd/*.tf",
    "modules/flux-cd/templates/values.yaml",
    "modules/postgres-cloud-native/*.tf",
    "modules/postgres-cloud-native-operator/*.tf",
    "modules/sage-aws-eks-addons/*.tf",
    "modules/sage-aws-k8s-node-autoscaler/*.tf",
    "modules/sage-aws-k8s-node-autoscaler/templates/values.yaml",
    "modules/trivy-operator/*.tf",
    "modules/victoria-metrics/*.tf",
  ]
}

resource "spacelift_environment_variable" "k8s-stack-deployments-environment-variables" {
  for_each = local.k8s_stack_deployments_variables

  stack_id   = spacelift_stack.k8s-stack-deployments.id
  name       = "TF_VAR_${each.key}"
  value      = try(tostring(each.value), jsonencode(each.value))
  write_only = false
}


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

