locals {
  alertmanager_enabled = var.smtp_from != "" && var.smtp_user != "" && var.smtp_password != ""
  telemetry_ui_enabled = var.enable_otel_ingress && var.oidc_client_id != "" && var.oidc_client_secret_otel != "" && var.hostname != ""
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
    targetRevision: 0.55.1
    helm:
      releaseName: signoz
      # Extra parameters to set (same as setting through values.yaml, but these take precedence)
      parameters:
      - name: "clickhouse.password"
        value: ${random_password.clickhouse-admin-password.result}
      %{if local.alertmanager_enabled}
      - name: "alertmanager.enabled"
        value: "true"
      - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_FROM"
        value: ${var.smtp_from}
      - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_AUTH_USERNAME"
        value: ${var.smtp_user}
      - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_AUTH_PASSWORD"
        value: ${var.smtp_password}
      %{else}
      - name: "alertmanager.enabled"
        value: "false"
      %{endif}
      valueFiles:
      - $values/modules/signoz/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  %{if var.enable_otel_ingress}
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    path: modules/signoz/resources-otel-collector-ingress
    kustomize:
      patches:
      - target:
          kind: ReferenceGrant
          name: allow-access-to-collector
        patch: |-
          - op: replace
            path: /spec/from/0/namespace
            value: ${var.gateway_namespace}
      - target:
          kind: HTTPRoute
          name: signoz-otel-collector-route
        patch: |-
          - op: replace
            path: /metadata/namespace
            value: ${var.gateway_namespace}
          - op: replace
            path: /spec/rules/0/backendRefs/0/namespace
            value: ${var.namespace}
      - target:
          kind: SecurityPolicy
          name: require-audience-for-authorization
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
                  - ${var.auth0_identifier}
          - op: replace
            path: /spec/authorization
            value:
              defaultAction: Deny
              rules:
              - name: allow
                action: Allow
                principal:
                  jwt:
                    provider: auth0
                    scopes:
                      - write:telemetry
  %{if local.telemetry_ui_enabled}
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    path: modules/signoz/resources-otel-ui-ingress
    kustomize:
      patches:
      - target:
          kind: HTTPRoute
          name: signoz-ui-route
        patch: |-
          - op: replace
            path: /metadata/namespace
            value: ${var.gateway_namespace}
          - op: replace
            path: /spec/rules/0/backendRefs/0/namespace
            value: ${var.namespace}
      - target:
          kind: SecurityPolicy
          name: signoz-ui-oidc-policy
        patch: |-
          - op: replace
            path: /metadata/namespace
            value: ${var.gateway_namespace}
          - op: replace
            path: /spec/oidc/clientID
            value: ${var.oidc_client_id}
          - op: replace
            path: /spec/oidc/redirectURL
            value: https://${var.hostname}/telemetry/ui/oauth2/callback
  %{endif}
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


resource "kubernetes_secret" "oidc-secret-ui" {
  count = local.telemetry_ui_enabled ? 1 : 0
  metadata {
    name      = "oidc-secret-telemetry"
    namespace = var.gateway_namespace
  }

  data = {
    "client-secret" = var.oidc_client_secret_otel
  }

  depends_on = [kubernetes_namespace.signoz]
}
