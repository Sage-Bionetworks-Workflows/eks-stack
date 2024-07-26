resource "kubernetes_namespace" "opentelemetry" {
  metadata {
    name = "opentelemetry"
  }
}

resource "helm_release" "opentelemetry" {
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = "opentelemetry"
  version    = "0.100.0"
  depends_on = [
    kubernetes_namespace.opentelemetry
  ]

  set {
    name  = "image.repository"
    value = "otel/opentelemetry-collector-k8s"
  }

  set {
    name  = "mode"
    value = "deployment"
  }

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
