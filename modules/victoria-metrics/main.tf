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
<<<<<<< HEAD
  version    = "0.24.3"
=======
  version    = "0.24.5"
>>>>>>> origin/ibcdpe-1007-split-into-vars
  depends_on = [
    kubernetes_namespace.victoria-metrics
  ]

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
