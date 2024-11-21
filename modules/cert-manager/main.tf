resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "cert-manager" {
  depends_on = [kubernetes_namespace.cert-manager]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://charts.jetstack.io'
    chart: cert-manager
    targetRevision: v1.15.1
    helm:
      releaseName: cert-manager
      valueFiles:
      - $values/modules/cert-manager/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
