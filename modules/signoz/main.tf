
resource "kubernetes_namespace" "signoz" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "signoz-deployment" {
  depends_on = [kubernetes_namespace.signoz]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: signoz
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://charts.signoz.io'
    chart: signoz
    targetRevision: 0.50.0
    helm:
      releaseName: signoz
      valueFiles:
      - $values/modules/signoz/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
