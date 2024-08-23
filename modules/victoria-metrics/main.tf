resource "kubernetes_namespace" "victoria-metrics" {
  metadata {
    name = "victoria-metrics"
  }
}

resource "kubectl_manifest" "argo-deployment" {
  depends_on = [kubernetes_namespace.victoria-metrics]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: victoria-metrics-k8s-stack
  namespace: argocd
spec:
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
    syncOptions:
    - ServerSideApply=true
  %{endif}
  project: default
  sources:
  - repoURL: 'https://victoriametrics.github.io/helm-charts/'
    chart: victoria-metrics-k8s-stack
    targetRevision: 0.24.5
    helm:
      releaseName: victoria-metrics-k8s-stack
      valueFiles:
      - $values/modules/victoria-metrics/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  ignoreDifferences:
  - group: "*"
    kind: "Secret"
    jsonPointers:
    - /data/admin-password
  - group: "apps"
    kind: "Deployment"
    jsonPointers:
    - /spec/template/metadata/annotations/checksum~1secret
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: victoria-metrics
YAML
}
