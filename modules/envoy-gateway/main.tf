
resource "kubernetes_namespace" "envoy-gateway" {
  metadata {
    name = var.namespace
  }
}

# TODO: Using kustomize in this fashion prints out the secret in the spacelift UI when terraform is running
resource "kubectl_manifest" "envoy-gateway" {
  depends_on = [kubernetes_namespace.envoy-gateway]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: envoy-gateway
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'oci://docker.io/envoyproxy/gateway-helm'
    chart: envoyproxy
    targetRevision: v1.1.2
    helm:
      releaseName: gateway-helm
      valueFiles:
      - $values/modules/envoy-gateway/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: signoz-testing
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
