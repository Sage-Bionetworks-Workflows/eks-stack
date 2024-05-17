module "kubernetes-controller" {
  source  = "spotinst/kubernetes-controller/ocean"
  version = "0.0.2"

  # Credentials
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = var.spotinst_account

  # Configuration
  cluster_identifier = var.cluster_name
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

resource "helm_release" "airflow" {
  name       = "apache-airflow"
  repository = "https://airflow.apache.org"
  chart      = "airflow"
  namespace  = "airflow"
  version    = "1.11.0"
  depends_on = [kubernetes_namespace.airflow]

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
