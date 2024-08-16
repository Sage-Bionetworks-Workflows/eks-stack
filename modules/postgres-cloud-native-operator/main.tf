locals {
  git_revision = "ibcdpe-1004-airflow-ops"
}

resource "kubernetes_namespace" "cnpg-system" {
  metadata {
    name = "cnpg-system"
  }
}

resource "kubectl_manifest" "argo-deployment-operator" {
  depends_on = [kubernetes_namespace.cnpg-system]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres-cloud-native-operator
  namespace: argocd
spec:
  project: default
  syncPolicy:
  %{if var.auto_deploy}
    automated:
      prune: ${var.auto_prune}
  %{endif}
    syncOptions:
    - ServerSideApply=true
  sources:
  - repoURL: 'https://cloudnative-pg.github.io/charts'
    chart: cloudnative-pg
    targetRevision: 0.21.6
    helm:
      releaseName: cloudnative-pg
      valueFiles:
      - $values/modules/postgres-cloud-native-operator/templates/operator-values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${local.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: cnpg-system
YAML
}