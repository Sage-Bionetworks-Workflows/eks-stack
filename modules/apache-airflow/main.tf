# Additional networking recs for the airflow deployment (To implement)
# Turn on network policies: https://github.com/apache/airflow/blob/main/chart/values.yaml#L225-L228
# Enable TLS: https://github.com/apache/airflow/blob/main/chart/values.yaml#L162-L170
# Test that connections to the airflow pods are blocked from the non-airflow namespaces - Except for `kube-system`

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = var.namespace
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
    namespace = var.namespace
  }

  data = {
    "webserver-secret-key" = random_password.airflow.result
  }

  depends_on = [kubernetes_namespace.airflow]
}

resource "random_password" "airflow-admin-user" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "airflow-admin-user-secret" {
  metadata {
    name      = "airflow-admin-user-secret"
    namespace = var.namespace
  }

  data = {
    "password" = random_password.airflow-admin-user.result
    "username" = "admin"
  }

  depends_on = [kubernetes_namespace.airflow]
}

resource "kubectl_manifest" "airflow-deployment" {
  depends_on = [kubernetes_namespace.airflow]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apache-airflow
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://airflow.apache.org'
    chart: airflow
    targetRevision: 1.11.0
    helm:
      releaseName: airflow
      valueFiles:
      - $values/modules/apache-airflow/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
