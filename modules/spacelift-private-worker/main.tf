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
  version    = "0.24.0"
  depends_on = [kubernetes_namespace.spacelift-workerpool]
}

resource "kubernetes_manifest" "test-workerpool" {
  // This is being conditionally created because of the required order of operations
  // The CRD must be created before the workerpool, so we need to wait for the helm release to be created
  count = var.create-worker-pool ? 1 : 0

  depends_on = [
    helm_release.spacelift-workerpool
  ]

  manifest = {
    apiVersion = "workers.spacelift.io/v1beta1"
    kind       = "WorkerPool"
    metadata = {
      name      = "test-workerpool"
      namespace = "spacelift-workerpool"
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
}

# How to create a K8 resource for the spacelift secrets:

# SPACELIFT_WP_TOKEN=<enter-token>
# SPACELIFT_WP_PRIVATE_KEY=<enter-base64-encoded-key>

# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Secret
# metadata:
#   name: test-workerpool
# type: Opaque
# stringData:
#   token: ${SPACELIFT_WP_TOKEN}
#   privateKey: ${SPACELIFT_WP_PRIVATE_KEY}
# EOF
