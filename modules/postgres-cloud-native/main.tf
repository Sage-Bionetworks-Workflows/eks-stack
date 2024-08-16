locals {
  git_revision = "ibcdpe-1004-airflow-ops"
}

resource "kubectl_manifest" "argo-deployment-database" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.argo_deployment_name}
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
    chart: cluster
    targetRevision: 0.0.9
    helm:
      releaseName: cluster-pg
      valueFiles:
      - $values/modules/postgres-cloud-native/templates/cluster-values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${local.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
