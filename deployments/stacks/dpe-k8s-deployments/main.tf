module "sage-aws-eks-autoscaler" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version = "0.6.0"

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
  version      = "0.4.8"
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
  version      = "0.3.5"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
  namespace    = "airflow"
}

module "argo-cd" {
  depends_on = [module.sage-aws-eks-autoscaler]
  source     = "spacelift.io/sagebionetworks/argo-cd/aws"
  version    = "0.3.1"
}

module "postgres-cloud-native-operator" {
  source       = "spacelift.io/sagebionetworks/postgres-cloud-native-operator/aws"
  version      = "0.3.1"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
}

module "postgres-cloud-native-database" {
  depends_on           = [module.postgres-cloud-native-operator, module.airflow]
  source               = "spacelift.io/sagebionetworks/postgres-cloud-native-database/aws"
  version              = "0.3.1"
  auto_deploy          = true
  auto_prune           = true
  git_revision         = var.git_revision
  namespace            = "airflow"
  argo_deployment_name = "airflow-postgres-cloud-native"
}
