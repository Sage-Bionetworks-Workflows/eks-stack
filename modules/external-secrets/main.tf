resource "kubernetes_namespace" "external_secrets" {
  metadata { name =  var.namespace }
}


# Argo CD Application that installs ESO from the official Helm repo
resource "kubectl_manifest" "external_secrets_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-secrets
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://charts.external-secrets.io'
    chart: external-secrets
    targetRevision: v0.19.1
    helm:
      releaseName: external-secrets
      valueFiles:
      - $values/modules/external-secrets/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: external-secrets
YAML
}