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

module "flux-cd" {
  depends_on = [module.sage-aws-eks-autoscaler]
  # source     = "spacelift.io/sagebionetworks/argo-cd/aws"
  # version    = "0.3.1"
  source = "../../../modules/flux-cd"
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
  enable_otel_ingress  = var.enable_otel_ingress && var.enable_cluster_ingress
  gateway_namespace    = "envoy-gateway"
  cluster_name         = var.cluster_name
  auth0_jwks_uri       = var.auth0_jwks_uri
  smtp_password        = var.smtp_password
  smtp_user            = var.smtp_user
  smtp_from            = var.smtp_from
}

module "signoz-flux-deployment" {
  depends_on           = [module.flux-cd]
  source               = "../../../modules/signoz-fluxcd"
  auto_deploy          = var.auto_deploy
  auto_prune           = var.auto_prune
  git_revision         = var.git_revision
  namespace            = "signoz-fluxcd"
  argo_deployment_name = "signoz-fluxcd"
  enable_otel_ingress  = var.enable_otel_ingress && var.enable_cluster_ingress
  gateway_namespace    = "envoy-gateway"
  cluster_name         = var.cluster_name
  auth0_jwks_uri       = var.auth0_jwks_uri
  smtp_password        = var.smtp_password
  smtp_user            = var.smtp_user
  smtp_from            = var.smtp_from
  aws_account_id       = var.aws_account_id
}

module "envoy-gateway" {
  count      = var.enable_cluster_ingress ? 1 : 0
  depends_on = [module.argo-cd]
  # source               = "spacelift.io/sagebionetworks/postgres-cloud-native-database/aws"
  # version              = "0.5.0"
  source               = "../../../modules/envoy-gateway"
  auto_deploy          = var.auto_deploy
  auto_prune           = var.auto_prune
  git_revision         = var.git_revision
  namespace            = "envoy-gateway"
  argo_deployment_name = "envoy-gateway"
  cluster_issuer_name  = "lets-encrypt-prod"
  ssl_hostname         = var.ssl_hostname
}

module "cert-manager" {
  count      = var.enable_cluster_ingress ? 1 : 0
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

module "clickhouse_backup_bucket" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "clickhouse-backup-${var.aws_account_id}-${var.cluster_name}"
}

resource "aws_iam_policy" "clickhouse_backup_policy" {
  name        = "clickhouse-backup-access-policy-${var.aws_account_id}-${var.cluster_name}"
  description = "Policy to access the clickhouse backup bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:CopyObject"
        ]
        Resource = [
          module.clickhouse_backup_bucket.bucket_arn,
          "${module.clickhouse_backup_bucket.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "clickhouse_backup_access" {
  name        = "clickhouse-backup-access-role-${var.aws_account_id}-${var.cluster_name}"
  description = "Assumed role to access the clickhouse backup policy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "${var.cluster_oidc_provider_arn}",
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "clickhouse_backup_policy_attachment" {
  role       = aws_iam_role.clickhouse_backup_access.name
  policy_arn = aws_iam_policy.clickhouse_backup_policy.arn
}
