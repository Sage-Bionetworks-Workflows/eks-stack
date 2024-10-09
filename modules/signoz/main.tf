
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
      - name: "alertmanager.additionalEnvs.ALERTMANAGER_SMTP_AUTH_PASSWORD"
        value: ${data.aws_secretsmanager_secret_version.smtp_password.secret_string}
      valueFiles:
      - $values/modules/signoz/templates/values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
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
