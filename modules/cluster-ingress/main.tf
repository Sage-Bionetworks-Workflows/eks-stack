resource "kubectl_manifest" "cluster-ingress" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.argo_deployment_name}
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1095-cluster-ingress-signoz
    path: modules/cluster-ingress/resources
    kustomize:
      patches:
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
                  uri: https://dev-57n3awu5je6q653y.us.auth0.com/.well-known/jwks.json
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}
