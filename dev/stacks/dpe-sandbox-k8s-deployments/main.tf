module "sage-aws-eks-autoscaler" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version = "0.4.2"

  cluster_name           = var.cluster_name
  cluster_name           = var.cluster_name
  private_vpc_subnet_ids = var.private_subnet_ids
  vpc_id                 = var.vpc_id
  node_security_group_id = var.node_security_group_id
  spotinst_account       = var.spotinst_account
  # desired_capacity       = 2
}

module "victoria-metrics" {
  source  = "spacelift.io/sagebionetworks/victoria-metrics/aws"
  version = "0.0.7"
}

module "trivy-operator" {
  source  = "spacelift.io/sagebionetworks/trivy-operator/aws"
  version = "0.0.12"
}

module "airflow" {
  source       = "spacelift.io/sagebionetworks/airflow/aws"
  version      = "0.0.1"
  cluster_name = var.cluster_name
}
