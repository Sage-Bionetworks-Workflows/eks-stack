resource "kubernetes_namespace" "trivy-system" {
  metadata {
    name = "trivy-system"
  }
}

resource "helm_release" "trivy-operator" {
  name       = "trivy-operator"
  repository = "https://aquasecurity.github.io/helm-charts/"
  chart      = "trivy-operator"
  namespace  = "trivy-system"
  version    = "0.24.1"
  depends_on = [
    kubernetes_namespace.trivy-system
  ]

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
