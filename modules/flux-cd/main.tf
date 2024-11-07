resource "kubernetes_namespace" "flux-system" {
  metadata {
    name = "flux-system"
  }
}

resource "helm_release" "fluxcd" {
  name       = "flux2"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  namespace  = "flux-system"
  version    = "2.14.0"
  depends_on = [kubernetes_namespace.flux-system]

  values = [templatefile("${path.module}/templates/values.yaml", {})]
}

resource "kubectl_manifest" "capacitor" {
  depends_on = [helm_release.fluxcd]

  yaml_body = <<YAML
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: capacitor
  namespace: flux-system
spec:
  targetNamespace: flux-system
  interval: 1h
  retryInterval: 2m
  timeout: 5m
  wait: true
  prune: true
  path: "./"
  sourceRef:
    kind: OCIRepository
    name: capacitor
YAML
}

resource "kubectl_manifest" "capacitor-kustomization" {
  depends_on = [helm_release.fluxcd]

  yaml_body = <<YAML
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: capacitor
  namespace: flux-system
spec:
  targetNamespace: flux-system
  interval: 1h
  retryInterval: 2m
  timeout: 5m
  wait: true
  prune: true
  path: "./"
  sourceRef:
    kind: OCIRepository
    name: capacitor
YAML
}
