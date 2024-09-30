
resource "kubernetes_namespace" "dex" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "dex" {
  depends_on = [kubernetes_namespace.dex]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dex
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://charts.dexidp.io'
    chart: dex
    targetRevision: 0.19.1
    helm:
      releaseName: dex
      valueFiles:
      - $values/modules/dex-idp/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: signoz-testing
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
