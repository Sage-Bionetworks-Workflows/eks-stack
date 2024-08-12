# Additional networking recs for the airflow deployment (To implement)
# Turn on network policies: https://github.com/apache/airflow/blob/main/chart/values.yaml#L225-L228
# Enable TLS: https://github.com/apache/airflow/blob/main/chart/values.yaml#L162-L170
# Test that connections to the airflow pods are blocked from the non-airflow namespaces - Except for `kube-system`

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

resource "kubectl_manifest" "argo-deployment" {
  depends_on = [kubernetes_namespace.airflow]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  sources:
  - repoURL: 'https://airflow.apache.org'
    chart: airflow
    targetRevision: 1.11.0
    helm:
      valueFiles:
      - $values/modules/apache-airflow/templates/airflow-values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1034-argocd
    ref: values
YAML
}

# TODO: Should a long-term deployment use a managed RDS instance?
# https://github.com/apache/airflow/blob/main/chart/values.yaml#L2321-L2329
# resource "helm_release" "airflow" {
#   name       = "apache-airflow"
#   repository = "https://airflow.apache.org"
#   chart      = "airflow"
#   namespace  = "airflow"
#   version    = "1.11.0"
#   depends_on = [kubernetes_namespace.airflow]

#   # https://github.com/hashicorp/terraform-provider-helm/issues/683#issuecomment-830872443
#   wait = false

#   set {
#     name  = "config.webserver.expose_config"
#     value = "true"
#   }

#   set {
#     name  = "config.secrets.backend"
#     value = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
#   }

#   set {
#     name  = "webserver.service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "webserverSecretKeySecretName"
#     value = "airflow-webserver-secret"
#   }

#   set {
#     name  = "airflowVersion"
#     value = "2.7.1"
#   }

#   set {
#     name  = "defaultAirflowRepository"
#     value = "bfaublesage/airflow"
#   }

#   set {
#     name  = "defaultAirflowTag"
#     value = "2.7.1-python-3.10"
#   }

#   set {
#     name  = "dags.persistence.enabled"
#     value = "false"
#   }

#   set {
#     name  = "dags.gitSync.enabled"
#     value = "true"
#   }

#   set {
#     name  = "dags.gitSync.repo"
#     value = "https://github.com/Sage-Bionetworks-Workflows/orca-recipes"
#   }

#   set {
#     name  = "dags.gitSync.subPath"
#     value = "dags"
#   }

#   set {
#     name  = "dags.gitSync.branch"
#     value = "main"
#   }


#   values = [templatefile("${path.module}/templates/airflow-values.yaml", {})]
# }
