resource "kubernetes_namespace" "trivy-system" {
  metadata {
    name = "trivy-system"
  }
}

resource "kubectl_manifest" "argo-deployment-trivy-operator" {
  depends_on = [kubernetes_namespace.trivy-system]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: trivy-operator
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://aquasecurity.github.io/helm-charts/'
    chart: trivy-operator
    targetRevision: 0.26.1
    helm:
      releaseName: trivy-operator
      valueFiles:
      - $values/modules/trivy-operator/templates/values-trivy-operator.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    path: modules/trivy-operator/resources
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: trivy-system
YAML
}

# converts the trivy-operator metrics to policy reporter format
resource "kubectl_manifest" "argo-deployment-trivy-operator-polr-adapter" {
  depends_on = [kubernetes_namespace.trivy-system]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: trivy-operator-polr-adapter
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://fjogeleit.github.io/trivy-operator-polr-adapter'
    chart: trivy-operator-polr-adapter
    targetRevision: 0.8.0
    helm:
      releaseName: trivy-operator-polr-adapter
      valueFiles:
      - $values/modules/trivy-operator/templates/values-trivy-operator-polr-adapter.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: trivy-system
YAML
}


# UI for viewing Policy Reports
resource "kubectl_manifest" "argo-deployment-policy-reporter" {
  depends_on = [kubernetes_namespace.trivy-system]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: policy-reporter
  namespace: argocd
spec:
  project: default
  %{if var.auto_deploy}
  syncPolicy:
    automated:
      prune: ${var.auto_prune}
  %{endif}
  sources:
  - repoURL: 'https://kyverno.github.io/policy-reporter'
    chart: policy-reporter
    targetRevision: 2.24.1
    helm:
      releaseName: policy-reporter
      valueFiles:
      - $values/modules/trivy-operator/templates/values-policy-reporter.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${var.git_revision}
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: trivy-system
YAML
}
