module "sage-aws-eks-autoscaler" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version = "0.5.0"

  cluster_name           = var.cluster_name
  private_vpc_subnet_ids = var.private_subnet_ids
  vpc_id                 = var.vpc_id
  node_security_group_id = var.node_security_group_id
  spotinst_account       = var.spotinst_account
  # desired_capacity       = 2
}

module "victoria-metrics" {
  depends_on   = [module.argo-cd, module.sage-aws-eks-autoscaler]
  source       = "spacelift.io/sagebionetworks/victoria-metrics/aws"
  version      = "0.4.7"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
}

module "trivy-operator" {
  depends_on   = [module.victoria-metrics, module.argo-cd, module.sage-aws-eks-autoscaler]
  source       = "spacelift.io/sagebionetworks/trivy-operator/aws"
  version      = "0.3.2"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
}

module "airflow" {
  depends_on   = [module.victoria-metrics, module.argo-cd, module.sage-aws-eks-autoscaler]
  source       = "spacelift.io/sagebionetworks/airflow/aws"
  version      = "0.3.1"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
}

module "argo-cd" {
  depends_on = [module.sage-aws-eks-autoscaler]
  source     = "spacelift.io/sagebionetworks/argo-cd/aws"
  version    = "0.3.1"
}


locals {
  my_branch_name                = "ibcdpe-1-branch-name"
  my_namespace_name             = "my-cool-namespace"
  my_application_name_in_argocd = "my-cool-application"
}


resource "kubernetes_namespace" "my-cool-namespace-resource" {
  metadata {
    name = local.my_namespace_name
  }
}

resource "kubectl_manifest" "my-argocd-application" {
  depends_on = [kubernetes_namespace.my-cool-namespace-resource]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${local.my_application_name_in_argocd}
  namespace: argocd
spec:
  project: default
  syncPolicy:
    automated:
      prune: true
  sources:
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${local.my_branch_name}
    path: deployments/stacks/dpe-k8s-deployments
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${local.my_namespace_name}
YAML
}
