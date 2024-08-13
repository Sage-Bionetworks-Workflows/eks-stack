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
  depends_on = [module.argo-cd]
  source     = "spacelift.io/sagebionetworks/victoria-metrics/aws"
  version    = "0.4.4"
}

module "trivy-operator" {
  depends_on = [module.victoria-metrics, module.argo-cd]
  source     = "spacelift.io/sagebionetworks/trivy-operator/aws"
  version    = "0.3.0"
}

module "airflow" {
  depends_on  = [module.victoria-metrics, module.argo-cd]
  source      = "spacelift.io/sagebionetworks/airflow/aws"
  version     = "0.3.0"
  auto_deploy = var.auto_deploy
  auto_prune  = var.auto_prune
}

module "argo-cd" {
  source  = "spacelift.io/sagebionetworks/argo-cd/aws"
  version = "0.3.1"
}
