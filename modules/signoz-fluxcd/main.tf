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


resource "aws_iam_user" "backup" {
  name = "clickhouse-backup-${var.namespace}"
}

resource "aws_iam_access_key" "backup" {
  user = aws_iam_user.backup.name
}

// Create the S3 bucket
resource "aws_s3_bucket" "clickhouse_backup" {
  bucket = "signoz-clickhouse-backup-${var.cluster_name}"
}

// Enable versioning
resource "aws_s3_bucket_versioning" "clickhouse_backup" {
  bucket = aws_s3_bucket.clickhouse_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Configure lifecycle rules for backup management
resource "aws_s3_bucket_lifecycle_configuration" "clickhouse_backup" {
  bucket = aws_s3_bucket.clickhouse_backup.id

  rule {
    id     = "cleanup_old_backups"
    status = "Enabled"

    expiration {
      days = 30  // Adjust retention period as needed
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_iam_user_policy" "backup" {
  name = "clickhouse-backup-policy"
  user = aws_iam_user.backup.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.clickhouse_backup.arn}/*",
          aws_s3_bucket.clickhouse_backup.arn
        ]
      }
    ]
  })
}

resource "kubernetes_config_map" "clickhouse-backup-config" {
  metadata {
    name      = "clickhouse-backup-config"
    namespace = var.namespace
  }

  data = {
    "config.yml" = <<-EOT
      general:
        remote_storage: s3
        upload_concurrency: 4
        download_concurrency: 4
        disable_progress_bar: false
      clickhouse:
        host: localhost
        port: 9000
        username: admin
        password_from_env: CLICKHOUSE_PASSWORD
      s3:
        bucket: ${aws_s3_bucket.clickhouse_backup.id}
        endpoint: s3.amazonaws.com
        region: us-east-1
        access_key: ${aws_iam_access_key.backup.id}
        secret_key: ${aws_iam_access_key.backup.secret}
    EOT
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
  postRenderers:
    - kustomize:
        patches:
          - target:
              kind: StatefulSet
              name: signoz-clickhouse
            patch: |
              - op: add
                path: /spec/template/spec/containers/-
                value:
                  name: backup
                  image: altinity/clickhouse-backup:2.4.4
                  imagePullPolicy: IfNotPresent
                  securityContext:
                    runAsUser: 101
                    runAsGroup: 101
                  env:
                    - name: CLICKHOUSE_HOST
                      value: "localhost"
                    - name: CLICKHOUSE_PORT
                      value: "9000"
                    - name: CLICKHOUSE_USER
                      value: "admin"
                    - name: CLICKHOUSE_PASSWORD
                      valueFrom:
                        secretKeyRef:
                          name: clickhouse-admin-password
                          key: password
                  volumeMounts:
                    - name: data
                      mountPath: /var/lib/clickhouse
                    - name: backup
                      mountPath: /var/lib/clickhouse/backup
                    - name: config
                      mountPath: /etc/clickhouse-backup
          - target:
              kind: StatefulSet
              name: signoz-clickhouse
            patch: |
              - op: add
                path: /spec/template/spec/volumes/-
                value:
                  name: backup
                  emptyDir: {}
              - op: add
                path: /spec/template/spec/volumes/-
                value:
                  name: config
                  configMap:
                    name: clickhouse-backup-config
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
