module "kubernetes-controller" {
  source  = "spotinst/kubernetes-controller/ocean"
  version = "0.0.2"

  # Credentials
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = var.spotinst_account

  # Configuration
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

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}

resource "random_password" "airflow" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "airflow_webserver_secret" {
  metadata {
    name      = "airflow-webserver-secret"
    namespace = "airflow"
  }

  data = {
    "webserver-secret-key" = random_password.airflow.result
  }

  depends_on = [kubernetes_namespace.airflow]
}

# TODO: Should a long-term deployment use a managed RDS instance?
# https://github.com/apache/airflow/blob/main/chart/values.yaml#L2321-L2329
resource "helm_release" "airflow" {
  name       = "apache-airflow"
  repository = "https://airflow.apache.org"
  chart      = "airflow"
  namespace  = "airflow"
  version    = "1.11.0"
  depends_on = [kubernetes_namespace.airflow]

  # https://github.com/hashicorp/terraform-provider-helm/issues/683#issuecomment-830872443
  wait = false

  set {
    name  = "config.webserver.expose_config"
    value = "true"
  }

  set {
    name  = "config.secrets.backend"
    value = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
  }

  set {
    name  = "webserver.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "webserverSecretKeySecretName"
    value = "airflow-webserver-secret"
  }

  set {
    name  = "airflowVersion"
    value = "2.7.1"
  }

  set {
    name  = "defaultAirflowRepository"
    value = "bfaublesage/airflow"
  }

  set {
    name  = "defaultAirflowTag"
    value = "2.7.1-python-3.10"
  }

  set {
    name  = "dags.persistence.enabled"
    value = "false"
  }

  set {
    name  = "dags.gitSync.enabled"
    value = "true"
  }

  set {
    name  = "dags.gitSync.repo"
    value = "https://github.com/Sage-Bionetworks-Workflows/orca-recipes"
  }

  set {
    name  = "dags.gitSync.subPath"
    value = "dags"
  }

  set {
    name  = "dags.gitSync.branch"
    value = "main"
  }


  values = [templatefile("${path.module}/templates/airflow-values.yaml", {})]
}
