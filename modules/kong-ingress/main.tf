
resource "kubernetes_namespace" "kong-ingress" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "kong-ingress" {
  depends_on = [kubernetes_namespace.kong-ingress]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kong-ingress
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://charts.konghq.com'
    chart: ingress
    targetRevision: 0.14.1
    helm:
      releaseName: kong-ingress
      valueFiles:
      - $values/modules/kong-ingress/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: signoz-testing
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
