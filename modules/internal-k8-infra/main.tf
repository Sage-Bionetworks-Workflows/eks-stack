module "kubernetes-controller" {
  source     = "spotinst/kubernetes-controller/ocean"
  version    = "0.0.2"
  depends_on = [module.ocean-aws-k8s]

  # Credentials
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = var.spotinst_account

  # Configuration
  cluster_identifier = var.cluster_name
}

module "ocean-aws-k8s" {
  source  = "spotinst/ocean-aws-k8s/spotinst"
  version = "1.2.0"

  # Configuration
  cluster_name                     = var.cluster_name
  region                           = var.region
  subnet_ids                       = data.aws_subnet.private.*.id
  worker_instance_profile_arn      = tolist(data.aws_iam_instance_profiles.profile.arns)[0]
  security_groups                  = data.aws_security_group.node.id
  is_aggressive_scale_down_enabled = true
  max_scale_down_percentage        = 33
  # Overwrite Name Tag and add additional
  # tags = {
  #   "kubernetes.io/cluster/tyu-spot-ocean" = "owned"
  # }
}
