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
    name      = "clickhouse-backup-service-account"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.aws_account_id}:role/clickhouse-backup-access-role-${var.aws_account_id}-${var.cluster_name}"
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
      reconcileStrategy: Revision
  values:
    clickhouse:
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: "arn:aws:iam::${var.aws_account_id}:role/clickhouse-backup-access-role-${var.aws_account_id}-${var.cluster_name}"
      coldStorage:
        enabled: true
        defaultKeepFreeSpaceBytes: "10485760" # 10MiB
        type: s3
        endpoint: https://clickhouse-backup-${var.aws_account_id}-${var.cluster_name}.us-east-1.s3.amazonaws.com/data/
        role:
          enabled: true
          annotations:
            eks.amazonaws.com/role-arn: "arn:aws:iam::${var.aws_account_id}:role/clickhouse-backup-access-role-${var.aws_account_id}-${var.cluster_name}"
  valuesFrom:
    - kind: ConfigMap
      name: signoz-values
      valuesKey: signoz_values.yaml
    - kind: Secret
      name: clickhouse-admin-password
      valuesKey: password
      targetPath: clickhouse.password
    - kind: Secret
      name: signoz-smtp-config
      valuesKey: smtp_config.yaml
  postRenderers:
    - kustomize:
        patches:
          # Add the sidecar container
          - target:
              kind: ClickHouseInstallation
            patch: |
              - op: add
                path: /spec/templates/podTemplates/0/spec/containers/-
                value:
                  name: clickhouse-backup-sidecar
                  image: altinity/clickhouse-backup:2.6.3
                  imagePullPolicy: IfNotPresent
                  args: ["server", "--watch"]
                  resources:
                    requests:
                      cpu: "100m"
                      memory: "128Mi"
                    limits:
                      cpu: "500m"
                      memory: "256Mi"
                  env:
                    - name: LOG_LEVEL
                      value: "debug"
                    - name: ALLOW_EMPTY_BACKUPS
                      value: "true"
                    - name: API_LISTEN
                      value: "0.0.0.0:7171"
                    - name: API_CREATE_INTEGRATION_TABLES
                      value: "true"
                    - name: BACKUPS_TO_KEEP_REMOTE
                      value: "3"
                    - name: REMOTE_STORAGE
                      value: "s3"
                    - name: WATCH_INTERVAL
                      value: "8h"
                    - name: FULL_INTERVAL
                      value: "24h"
                    - name: BACKUP_NAME
                      value: "clickhouse-backup-${var.aws_account_id}-${var.cluster_name}"
                    - name: S3_BUCKET
                      value: "clickhouse-backup-${var.aws_account_id}-${var.cluster_name}"
                    - name: S3_PATH
                      value: "backup/shard-{shard}"
                  ports:
                    - name: backup-rest
                      containerPort: 7171
            - target:
                kind: ClickHouseInstallation
              patch: |
                - op: add
                  path: /spec/configuration/files/config.d/storage.xml/clickhouse/storage_configuration/disks/s3/region
                  value: "us-east-1"
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

resource "kubectl_manifest" "signoz-git-repo" {
  depends_on = [kubectl_manifest.signoz-helm-release]

  yaml_body = <<YAML
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: signoz-additional-resources
  namespace: ${var.namespace}
spec:
  interval: 1m
  ref:
    branch: ${var.git_revision}
  url: https://github.com/Sage-Bionetworks-Workflows/eks-stack
YAML
}

resource "kubectl_manifest" "signoz-kustomization" {
  depends_on = [kubectl_manifest.signoz-git-repo, kubectl_manifest.signoz-helm-release]

  yaml_body = <<YAML
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: signoz-additional-resources
  namespace: ${var.namespace}
spec:
  targetNamespace: ${var.namespace}
  interval: 1h
  retryInterval: 2m
  timeout: 5m
  wait: true
  prune: true
  path: "./modules/signoz-fluxcd/resources"
  sourceRef:
    kind: GitRepository
    name: signoz-additional-resources
YAML
}

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

resource "kubernetes_secret" "signoz-smtp-config" {
  metadata {
    name      = "signoz-smtp-config"
    namespace = var.namespace
  }

  data = {
    "smtp_config.yaml" = <<YAML
alertmanager:
  enabled: ${local.alertmanager_enabled ? "true" : "false"}
  additionalEnvs:
    ALERTMANAGER_SMTP_FROM: ${local.alertmanager_enabled ? var.smtp_from : ""}
    ALERTMANAGER_SMTP_AUTH_USERNAME: ${local.alertmanager_enabled ? var.smtp_user : ""}
    ALERTMANAGER_SMTP_AUTH_PASSWORD: ${local.alertmanager_enabled ? var.smtp_password : ""}
YAML
  }

  depends_on = [kubernetes_namespace.signoz]
}
