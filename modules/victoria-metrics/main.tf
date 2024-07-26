resource "kubernetes_namespace" "victoria-metrics" {
  metadata {
    name = "victoria-metrics"
  }
}

resource "helm_repository" "grafana" {
  name = "grafana"
  url  = "https://grafana.github.io/helm-charts"
}

resource "helm_repository" "prometheus-community" {
  name = "prometheus-community"
  url  = "https://prometheus-community.github.io/helm-charts"
}

resource "helm_release" "victoria-metrics" {
  name       = "victoria-metrics-k8s-stack"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-k8s-stack"
  namespace  = "victoria-metrics"
  version    = "0.9.25"
  depends_on = [
    kubernetes_namespace.victoria-metrics,
    helm_repository.grafana,
    helm_repository.prometheus-community
  ]

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
