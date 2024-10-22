
resource "kubernetes_namespace" "envoy-gateway" {
  metadata {
    name = var.namespace
  }
}
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
  - repoURL: registry-1.docker.io
    chart: envoyproxy/gateway-helm
    targetRevision: v1.1.2
    helm:
      releaseName: gateway-helm
      valueFiles:
      - $values/modules/envoy-gateway/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1095-cluster-ingress-signoz
    ref: values
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1095-cluster-ingress-signoz
    path: modules/envoy-gateway/resources
    kustomize:
      patches:
      - target:
          kind: ClusterIssuer
        patch: |-
          - op: replace
            path: /metadata/name
            value: ${var.cluster_issuer_name}
      - target:
          kind: GatewayClass
        patch: |-
          - op: replace
            path: /spec/parametersRef/namespace
            value: ${var.namespace}
      - target:
          kind: Gateway
        patch: |-
          - op: replace
            path: /metadata/annotations/cert-manager.io~1cluster-issuer
            value: ${var.cluster_issuer_name}
          - op: replace
            path: /spec/listeners/0/hostname
            value: ${var.ssl_hostname}
      - target:
          kind: ClusterIssuer
        patch: |-
          - op: replace
            path: /metadata/name
            value: ${var.cluster_issuer_name}
      - target:
          kind: SecurityPolicy
        patch: |-
          - op: replace
            path: /spec/jwt/providers
            value:
              - name: auth0
                remoteJWKS:
                  uri: ${var.auth0_jwks_uri}
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
