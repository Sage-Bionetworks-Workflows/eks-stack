resource "kubernetes_namespace" "spacelift-workerpool" {
  metadata {
    name = "spacelift-workerpool"
  }
}


resource "helm_release" "spacelift-workerpool" {
  name       = "spacelift-workerpool-controller"
  repository = "https://downloads.spacelift.io/helm"
  chart      = "spacelift-workerpool-controller"
  namespace  = "spacelift-workerpool"
  version    = "0.1.0"
  depends_on = [kubernetes_namespace.spacelift-workerpool]
}

resource "kubernetes_manifest" "test_workerpool" {
  manifest = {
    apiVersion = "workers.spacelift.io/v1beta1"
    kind       = "WorkerPool"
    metadata = {
      name      = "test-workerpool"
      namespace = "spacelift-workerpool" # Assuming it's the same namespace as the helm_release
    }
    spec = {
      poolSize = 2
      token = {
        secretKeyRef = {
          name = "test-workerpool"
          key  = "token"
        }
      }
      privateKey = {
        secretKeyRef = {
          name = "test-workerpool"
          key  = "privateKey"
        }
      }
    }
  }

  depends_on = [
    helm_release.spacelift-workerpool
  ]
}
