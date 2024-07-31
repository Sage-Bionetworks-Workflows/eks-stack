resource "kubernetes_namespace" "victoria-metrics" {
  metadata {
    name = "victoria-metrics"
  }
}

resource "helm_release" "victoria-metrics" {
  name       = "victoria-metrics-k8s-stack"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-k8s-stack"
  namespace  = "victoria-metrics"
  version    = "0.24.3"
  depends_on = [
    kubernetes_namespace.victoria-metrics
  ]

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
