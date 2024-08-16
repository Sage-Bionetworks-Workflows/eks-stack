locals {
  git_revision = "ibcdpe-1004-airflow-ops"
}

resource "kubernetes_namespace" "cnpg-system" {
  metadata {
    name = "cnpg-system"
  }
}

resource "kubectl_manifest" "argo-deployment-operator" {
  depends_on = [kubernetes_namespace.cnpg-system]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres-cloud-native-operator
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
    chart: cloudnative-pg
    targetRevision: 0.21.6
    helm:
      releaseName: cloudnative-pg
      valueFiles:
      - $values/modules/postgres-cloud-native/templates/operator-values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${local.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: cnpg-system
YAML
}

resource "kubernetes_namespace" "cnpg-database" {
  metadata {
    name = "cnpg-database"
  }
}

resource "kubectl_manifest" "argo-deployment-database" {
  depends_on = [kubernetes_namespace.cnpg-database, resource.kubectl_manifest.argo-deployment-operator]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres-cloud-native-database
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
      releaseName: cluster-pg
      valueFiles:
      - $values/modules/postgres-cloud-native/templates/cluster-values.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${local.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: cnpg-database
YAML
}

# TODO: Secrets should be moved out to AWS secrets manager
resource "random_password" "airflow-pg-password" {
  length = 20
}

# TODO: This will need to be copied over to the airflow NS as well
resource "kubernetes_secret" "airflow-user-secret" {
  metadata {
    name      = "airflow-user-secret"
    namespace = "cnpg-database"
    labels = {
      "cnpg.io/reload" = "true"
    }
  }

  type = "kubernetes.io/basic-auth"


  data = {
    "username" = "apache-airflow"
    "password" = random_password.airflow-pg-password.result
  }

  depends_on = [kubernetes_namespace.cnpg-database]
}
