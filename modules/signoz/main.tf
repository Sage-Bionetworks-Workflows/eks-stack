locals {
  alertmanager_enabled = var.smtp_from != "" && var.smtp_user != "" && var.smtp_password != ""
}

resource "kubernetes_namespace" "signoz" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "signoz-deployment" {
  depends_on = [kubernetes_namespace.signoz]
  
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: signoz
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://charts.signoz.io'
    chart: signoz
    targetRevision: 0.50.0
    helm:
      releaseName: signoz
      # Extra parameters to set (same as setting through values.yaml, but these take precedence)
      parameters:
      - name: "clickhouse.password"
        value: ${random_password.clickhouse-admin-password.result}
      %{if local.alertmanager_enabled}
      - name: "alertmanager.enabled"
        value: true
      - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_FROM"
        value: ${var.smtp_from}
      - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_AUTH_USERNAME"
        value: ${var.smtp_user}
      - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_AUTH_PASSWORD"
        value: ${var.smtp_password}
      %{else}
      - name: "alertmanager.enabled"
        value: false
      - name: "alertmanager.enableda"
        value: ${var.smtp_user}
      - name: "alertmanager.enabledb"
        value: ${var.smtp_from}
      - name: "alertmanager.enabledc"
        value: ${var.smtp_password != ""}
      %{endif}
      valueFiles:
      - $values/modules/signoz/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  %{if var.enable_otel_ingress}
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    path: modules/signoz/resources-otel-ingress
    kustomize:
      patches:
      - target:
          kind: ReferenceGrant
        patch: |-
          - op: replace
            path: /spec/from/0/namespace
            value: ${var.gateway_namespace}
      - target:
          kind: HTTPRoute
        patch: |-
          - op: replace
            path: /metadata/namespace
            value: ${var.gateway_namespace}
          - op: replace
            path: /spec/rules/0/backendRefs/0/namespace
            value: ${var.namespace}
      - target:
          kind: SecurityPolicy
        patch: |-
          - op: replace
            path: /metadata/namespace
            value: ${var.gateway_namespace}
          - op: replace
            path: /spec/jwt/providers
            value:
              - name: auth0
                remoteJWKS:
                  uri: ${var.auth0_jwks_uri}
                audiences:
                  - ${var.cluster_name}-telemetry
  %{endif}
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
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
