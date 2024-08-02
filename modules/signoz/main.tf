resource "kubernetes_namespace" "signoz" {
  metadata {
    name = "signoz"
  }
}

resource "helm_release" "signoz" {
  name       = "signoz"
  repository = "https://charts.signoz.io"
  chart      = "signoz"
  namespace  = "signoz"
  version    = "0.47.0"
  depends_on = [
    kubernetes_namespace.signoz
  ]
  timeout = 900
  wait    = false

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
