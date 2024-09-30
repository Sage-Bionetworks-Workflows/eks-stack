
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
  name: kong
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
      releaseName: kong
      valueFiles:
      - $values/modules/kong-ingress/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: signoz-testing
    ref: values
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    path: modules/kong-ingress/resources
    kustomize:
      patches:
      - target:
          kind: KongClusterPlugin
        patch: |-
          - op: replace
            path: /config/client_id/0
            value: ${data.aws_secretsmanager_secret_version.client-id.secret_string}
          - op: replace
            path: /config/client_secret/0
            value: ${data.aws_secretsmanager_secret_version.client-secret.secret_string}
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
