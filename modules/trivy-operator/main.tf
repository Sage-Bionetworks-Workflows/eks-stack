resource "kubernetes_namespace" "trivy-system" {
  metadata {
    name = "trivy-system"
  }
}

resource "helm_release" "trivy-operator" {
  name       = "trivy-operator"
  repository = "https://aquasecurity.github.io/helm-charts/"
  chart      = "trivy-operator"
  namespace  = "trivy-system"
  version    = "0.24.1"
  depends_on = [
    kubernetes_namespace.trivy-system
  ]

  values = [templatefile("${path.module}/templates/values-trivy-operator.yaml", {})]
}

resource "kubectl_manifest" "vmservicescrape" {
  depends_on = [helm_release.trivy-operator]

  yaml_body = <<YAML
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMServiceScrape
metadata:
  name: trivy-vmservicescrape
  namespace: ${kubernetes_namespace.trivy-system.metadata[0].name}
spec:
  endpoints:
    - port: metrics
  selector:
    matchLabels:
      app.kubernetes.io/name: trivy-operator
YAML
}

# converts the trivy-operator metrics to policy reporter format
resource "helm_release" "trivy-operator-polr-adapter" {
  name       = "trivy-operator-polr-adapter"
  repository = "https://fjogeleit.github.io/trivy-operator-polr-adapter"
  chart      = "trivy-operator-polr-adapter"
  namespace  = "trivy-system"
  version    = "0.8.0"
  depends_on = [
    kubernetes_namespace.trivy-system
  ]

  values = [templatefile("${path.module}/templates/values-trivy-operator-polr-adapter.yaml", {})]
}

# UI for viewing Policy Reports
resource "helm_release" "policy-reporter" {
  name       = "policy-reporter"
  repository = "https://kyverno.github.io/policy-reporter"
  chart      = "policy-reporter"
  namespace  = "trivy-system"
  version    = "2.24.1"
  depends_on = [
    kubernetes_namespace.trivy-system,
    helm_release.trivy-operator-polr-adapter
  ]

  values = [templatefile("${path.module}/templates/values-policy-reporter.yaml", {})]
}
