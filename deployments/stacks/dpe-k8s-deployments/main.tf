module "sage-aws-eks-autoscaler" {
  source                 = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version                = "0.9.0"
  cluster_name           = var.cluster_name
  private_vpc_subnet_ids = var.private_subnet_ids_eks_worker_nodes
  vpc_id                 = var.vpc_id
  node_security_group_id = var.node_security_group_id
  spotinst_account       = var.spotinst_account
  single_az              = false
  desired_capacity       = 3
}

module "sage-aws-eks-addons" {
  source             = "spacelift.io/sagebionetworks/sage-aws-eks-addons/aws"
  version            = "0.3.0"
  cluster_name       = var.cluster_name
  aws_account_id     = var.aws_account_id
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids_eks_worker_nodes
}

module "argo-cd" {
  depends_on = [module.sage-aws-eks-autoscaler]
  # source     = "spacelift.io/sagebionetworks/argo-cd/aws"
  # version    = "0.3.1"
  source = "../../../modules/argo-cd"
}

module "victoria-metrics" {
  depends_on   = [module.argo-cd]
  source       = "spacelift.io/sagebionetworks/victoria-metrics/aws"
  version      = "0.4.8"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
}

module "trivy-operator" {
  depends_on   = [module.victoria-metrics, module.argo-cd]
  source       = "spacelift.io/sagebionetworks/trivy-operator/aws"
  version      = "0.3.2"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
}

module "airflow" {
  depends_on   = [module.victoria-metrics, module.argo-cd]
  source       = "spacelift.io/sagebionetworks/airflow/aws"
  version      = "0.4.0"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
  namespace    = "airflow"
}

module "postgres-cloud-native-operator" {
  depends_on   = [module.argo-cd]
  source       = "spacelift.io/sagebionetworks/postgres-cloud-native-operator/aws"
  version      = "0.4.0"
  auto_deploy  = var.auto_deploy
  auto_prune   = var.auto_prune
  git_revision = var.git_revision
}

module "postgres-cloud-native-database" {
  depends_on           = [module.postgres-cloud-native-operator, module.airflow, module.argo-cd]
  source               = "spacelift.io/sagebionetworks/postgres-cloud-native-database/aws"
  version              = "0.5.0"
  auto_deploy          = var.auto_deploy
  auto_prune           = var.auto_prune
  git_revision         = var.git_revision
  namespace            = "airflow"
  argo_deployment_name = "airflow-postgres-cloud-native"
}


module "signoz" {
  depends_on = [module.argo-cd]
  # source               = "spacelift.io/sagebionetworks/postgres-cloud-native-database/aws"
  # version              = "0.5.0"
  source               = "../../../modules/signoz"
  auto_deploy          = var.auto_deploy
  auto_prune           = var.auto_prune
  git_revision         = var.git_revision
  namespace            = "signoz"
  argo_deployment_name = "signoz"
  cluster_name         = var.cluster_name
  enable_otel_ingress  = true
}

module "envoy-gateway" {
  depends_on = [module.argo-cd]
  # source               = "spacelift.io/sagebionetworks/postgres-cloud-native-database/aws"
  # version              = "0.5.0"
  source               = "../../../modules/envoy-gateway"
  auto_deploy          = var.auto_deploy
  auto_prune           = var.auto_prune
  git_revision         = var.git_revision
  namespace            = "envoy-gateway"
  argo_deployment_name = "envoy-gateway"
}

module "cert-manager" {
  depends_on = [module.argo-cd]
  # source               = "spacelift.io/sagebionetworks/postgres-cloud-native-database/aws"
  # version              = "0.5.0"
  source               = "../../../modules/cert-manager"
  auto_deploy          = var.auto_deploy
  auto_prune           = var.auto_prune
  git_revision         = var.git_revision
  namespace            = "cert-manager"
  argo_deployment_name = "cert-manager"
}

module "cluster-ingress" {
  depends_on = [module.argo-cd]
  # source               = "spacelift.io/sagebionetworks/postgres-cloud-native-database/aws"
  # version              = "0.5.0"
  source               = "../../../modules/cluster-ingress"
  auto_deploy          = var.auto_deploy
  auto_prune           = var.auto_prune
  git_revision         = var.git_revision
  namespace            = "envoy-gateway"
  argo_deployment_name = "cluster-ingress"

  # To determine more elegant ways to fill in these values, for example, if we have
  # a pre-defined DNS name for the cluster (https://sagebionetworks.jira.com/browse/IT-3931)
  ssl_hostname        = "unknown-to-fill-in"
  cluster_issuer_name = "selfsigned"
}
