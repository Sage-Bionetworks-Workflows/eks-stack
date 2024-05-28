module "ocean-controller" {
  source = "spotinst/ocean-controller/spotinst"
  version = "0.54.0"

  # Credentials.
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = var.spotinst_account

  # Configuration.
  cluster_identifier = var.cluster_name
}

module "ocean-aws-k8s" {
  source  = "spotinst/ocean-aws-k8s/spotinst"
  version = "1.2.0"
  # worker_instance_profile_arn      = "arn:aws:iam::766808016710:role/airflow-node-group-eks-node-group-20240517054613935800000001"

  # Configuration
  cluster_name                     = var.cluster_name
  region                           = var.region
  subnet_ids                       = data.aws_subnets.node_subnets.ids
  worker_instance_profile_arn      = tolist(data.aws_eks_node_group.node_group.node_role_arn)[0]
  security_groups                  = [data.aws_security_group.eks_cluster_security_group.id]
  is_aggressive_scale_down_enabled = true
  max_scale_down_percentage        = 33
  tags                             = var.tags
}
