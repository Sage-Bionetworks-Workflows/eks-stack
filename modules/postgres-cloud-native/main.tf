resource "kubectl_manifest" "argo-deployment-database" {
  depends_on = [
    kubernetes_secret.connection-secret
  ]
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.argo_deployment_name}
  namespace: argocd
spec:
  project: default
  syncPolicy:
  %{if var.auto_deploy}
    automated:
      prune: ${var.auto_prune}
  %{endif}
    syncOptions:
    - ServerSideApply=true
  sources:
  - repoURL: 'https://cloudnative-pg.github.io/charts'
    chart: cluster
    targetRevision: 0.0.9
    helm:
      releaseName: ${var.argo_deployment_name}
      valueFiles:
      - $values/modules/postgres-cloud-native/templates/cluster-values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    path: modules/postgres-cloud-native/resources
    kustomize:
      patches:
      - target:
          kind: Pooler
        patch: |-
          - op: replace
            path: /spec/cluster/name
            value: ${var.argo_deployment_name}-cluster
          - op: replace
            path: /spec/instances
            value: 2
          - op: replace
            path: /metadata/name
            value: ${var.argo_deployment_name}-pooler-rw
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${var.namespace}
YAML
}

resource "random_password" "pg-password" {
  length  = 64
  special = false
}

resource "kubernetes_secret" "connection-secret" {
  metadata {
    name      = "pg-user-secret"
    namespace = var.namespace
    labels = {
      "cnpg.io/reload"  = "true"
      "cnpg.io/cluster" = var.argo_deployment_name
    }
  }

  type = "kubernetes.io/basic-auth"


  data = {
    "dbname"     = "application-database"
    "host"       = "${var.argo_deployment_name}-pooler-rw.${var.namespace}"
    "jdbc-uri"   = "jdbc:postgresql://${var.argo_deployment_name}-pooler-rw.${var.namespace}:5432/application-database?password=${random_password.pg-password.result}&user=application-database"
    "password"   = random_password.pg-password.result
    "pgpass"     = "${var.argo_deployment_name}-pooler-rw:5432:application-database:application-database:${random_password.pg-password.result}"
    "port"       = "5432"
    "uri"        = "postgresql://application-database:${random_password.pg-password.result}@${var.argo_deployment_name}-pooler-rw.${var.namespace}:5432/application-database"
    "user"       = "application-database"
    "username"   = "application-database"
    "connection" = "postgresql://application-database:${random_password.pg-password.result}@${var.argo_deployment_name}-pooler-rw.${var.namespace}:5432/application-database"
  }
}
