locals {
  alertmanager_enabled = var.smtp_from != "" && var.smtp_user != "" && var.smtp_password != ""
}

resource "kubernetes_namespace" "signoz" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "signoz-helm-repo" {
  depends_on = [kubernetes_namespace.signoz]

  yaml_body = <<YAML
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: signoz
  namespace: ${var.namespace}
spec:
  interval: 24h
  url: https://charts.signoz.io
YAML
}

resource "kubernetes_config_map" "signoz-values" {
  metadata {
    name      = "signoz-values"
    namespace = var.namespace
  }

  data = {
    "signoz_values.yaml" = "${file("${path.module}/templates/values.yaml")}"
  }

}

resource "kubernetes_service_account" "clickhouse-backup-service-account" {
  metadata {
    name      = "clickhouse-backup"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.aws_account_id}:role/clickhouse-backup-access-role"
    }
  }
}

resource "kubectl_manifest" "signoz-helm-release" {
  depends_on = [kubernetes_namespace.signoz]

  yaml_body = <<YAML
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: signoz
  namespace: ${var.namespace}
spec:
  interval: 10m
  chart:
    spec:
      chart: signoz
      version: '0.55.1'
      sourceRef:
        kind: HelmRepository
        name: signoz
        namespace: ${var.namespace}
      interval: 10m
  values:
    alertmanager:
      enabled: false
  valuesFrom:
    - kind: ConfigMap
      name: signoz-values
      valuesKey: signoz_values.yaml
    - kind: Secret
      name: clickhouse-admin-password
      valuesKey: password
      targetPath: clickhouse.password
    - kind: Secret
      name: aws-credentials
      valuesKey: aws_access_key_id
      targetPath: clickhouse.s3.accessKey
    - kind: Secret
      name: aws-credentials
      valuesKey: aws_secret_access_key
      targetPath: clickhouse.s3.secretKey
  postRenderers:
    - kustomize:
        patches:
          - target:
              version: v1
              kind: Deployment
              name: clickhouse-backup
            patch: |
              ${file("${path.module}/templates/clickhouse-backup-patch.yaml")}
YAML
}

# resource "kubectl_manifest" "signoz-deployment" {
#   depends_on = [kubernetes_namespace.signoz]

#   yaml_body = <<YAML
# apiVersion: argoproj.io/v1alpha1
# kind: Application
# metadata:
#   name: signoz
#   namespace: argocd
# spec:
#   project: default
#   %{if var.auto_deploy}
#   syncPolicy:
#     automated:
#       prune: ${var.auto_prune}
#   %{endif}
#   sources:
#   - repoURL: 'https://charts.signoz.io'
#     chart: signoz
#     targetRevision: 0.55.1
#     helm:
#       releaseName: signoz
#       # Extra parameters to set (same as setting through values.yaml, but these take precedence)
#       parameters:
#       - name: "clickhouse.password"
#         value: ${random_password.clickhouse-admin-password.result}
#       %{if local.alertmanager_enabled}
#       - name: "alertmanager.enabled"
#         value: "true"
#       - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_FROM"
#         value: ${var.smtp_from}
#       - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_AUTH_USERNAME"
#         value: ${var.smtp_user}
#       - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_AUTH_PASSWORD"
#         value: ${var.smtp_password}
#       %{else}
#       - name: "alertmanager.enabled"
#         value: "false"
#       %{endif}
#       valueFiles:
#       - $values/modules/signoz/templates/values.yaml
#   - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
#     targetRevision: ${var.git_revision}
#     ref: values
#   %{if var.enable_otel_ingress}
#   - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
#     targetRevision: ${var.git_revision}
#     path: modules/signoz/resources-otel-ingress
#     kustomize:
#       patches:
#       - target:
#           kind: ReferenceGrant
#         patch: |-
#           - op: replace
#             path: /spec/from/0/namespace
#             value: ${var.gateway_namespace}
#       - target:
#           kind: HTTPRoute
#         patch: |-
#           - op: replace
#             path: /metadata/namespace
#             value: ${var.gateway_namespace}
#           - op: replace
#             path: /spec/rules/0/backendRefs/0/namespace
#             value: ${var.namespace}
#       - target:
#           kind: SecurityPolicy
#         patch: |-
#           - op: replace
#             path: /metadata/namespace
#             value: ${var.gateway_namespace}
#           - op: replace
#             path: /spec/jwt/providers
#             value:
#               - name: auth0
#                 remoteJWKS:
#                   uri: ${var.auth0_jwks_uri}
#                 audiences:
#                   - ${var.cluster_name}-telemetry
#   %{endif}
#   destination:
#     server: 'https://kubernetes.default.svc'
#     namespace: ${var.namespace}
# YAML
# }


resource "random_password" "clickhouse-admin-password" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "clickhouse-admin-password" {
  metadata {
    name      = "clickhouse-admin-password"
    namespace = var.namespace
  }

  data = {
    "password" = random_password.clickhouse-admin-password.result
  }

  depends_on = [kubernetes_namespace.signoz]
}

resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = var.namespace
  }

  data = {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
  }
}
