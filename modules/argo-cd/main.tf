resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argo-cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "7.4.3"
  depends_on = [kubernetes_namespace.argocd]

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}
