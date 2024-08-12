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
  namespace: argo-cd
spec:
  project: default
  sources:
  - repoURL: 'https://aquasecurity.github.io/helm-charts/'
    chart: trivy-operator
    targetRevision: 0.24.1
    helm:
      releaseName: trivy-operator
      valueFiles:
      - $values/modules/trivy-operator/templates/values-trivy-operator.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1034-argocd
    ref: values
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1034-argocd
    path: modules/trivy-operator/resources
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: trivy-system
YAML
}


# resource "kubectl_manifest" "vmservicescrape" {
#   depends_on = [helm_release.trivy-operator]

#   yaml_body = <<YAML
# apiVersion: operator.victoriametrics.com/v1beta1
# kind: VMServiceScrape
# metadata:
#   name: trivy-vmservicescrape
#   namespace: ${kubernetes_namespace.trivy-system.metadata[0].name}
# spec:
#   endpoints:
#     - port: metrics
#   selector:
#     matchLabels:
#       app.kubernetes.io/name: trivy-operator
# YAML
# }

# converts the trivy-operator metrics to policy reporter format
resource "kubectl_manifest" "argo-deployment-trivy-operator-polr-adapter" {
  depends_on = [kubernetes_namespace.trivy-system]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: trivy-operator-polr-adapter
  namespace: argo-cd
spec:
  project: default
  sources:
  - repoURL: 'https://fjogeleit.github.io/trivy-operator-polr-adapter'
    chart: trivy-operator-polr-adapter
    targetRevision: 0.8.0
    helm:
      releaseName: trivy-operator-polr-adapter
      valueFiles:
      - $values/modules/trivy-operator/templates/values-trivy-operator-polr-adapter.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1034-argocd
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
  namespace: argo-cd
spec:
  project: default
  sources:
  - repoURL: 'https://kyverno.github.io/policy-reporter'
    chart: policy-reporter
    targetRevision: 2.24.1
    helm:
      releaseName: policy-reporter
      valueFiles:
      - $values/modules/trivy-operator/templates/values-policy-reporter.yaml
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ibcdpe-1034-argocd
    ref: values
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: trivy-system
YAML
}
