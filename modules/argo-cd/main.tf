resource "kubernetes_namespace" "argo-cd" {
  metadata {
    name = "argo-cd"
  }
}

resource "helm_release" "argo-cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argo-cd"
  version    = "7.4.3"
  depends_on = [kubernetes_namespace.argo-cd]

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
