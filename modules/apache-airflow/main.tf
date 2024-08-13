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


# TODO: Should a long-term deployment use a managed RDS instance?
# https://github.com/apache/airflow/blob/main/chart/values.yaml#L2321-L2329
resource "kubectl_manifest" "argo-deployment" {
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
    targetRevision: ibcdpe-1034-argocd
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: airflow
YAML
}
