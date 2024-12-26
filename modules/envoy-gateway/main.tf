
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
    targetRevision: v1.2.1
    helm:
      releaseName: gateway-helm
      valueFiles:
      - $values/modules/envoy-gateway/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
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
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}

resource "kubernetes_secret" "docker-cfg" {
  metadata {
    name      = "docker-cfg"
    namespace = var.namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.docker_server}" = {
          "username" = var.docker_username,
          "password" = var.docker_access_token,
          "email"    = var.docker_email
          "auth"     = base64encode("${var.docker_username}:${var.docker_access_token}")
        }
      }
    })
  }
}
