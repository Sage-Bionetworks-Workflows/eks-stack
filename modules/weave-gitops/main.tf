resource "kubernetes_namespace" "weave" {
  metadata {
    name = var.namespace
  }
}

resource "kubectl_manifest" "weave-git-repo" {
  depends_on = [kubernetes_namespace.weave]

  yaml_body = <<YAML
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: gitops-server
  namespace: ${var.namespace}
spec:
  interval: 24h
  url: https://github.com/weaveworks/weave-gitops
  ref:
    branch: main
  ignore: |-
    # exclude all
    /*
    # include charts directory
    !/charts/
YAML
}

resource "kubernetes_config_map" "weave-values" {
  metadata {
    name      = "weave-values"
    namespace = var.namespace
  }

  data = {
    "values.yaml" = "${file("${path.module}/templates/values.yaml")}"
  }

}

resource "kubectl_manifest" "weave-helm-release" {
  depends_on = [kubernetes_namespace.weave]

  yaml_body = <<YAML
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: weave-gitops
  namespace: ${var.namespace}
spec:
  interval: 10m
  releaseName: gitops-server
  chart:
    spec:
      chart: charts/gitops-server
      sourceRef:
        kind: GitRepository
        name: gitops-server
  valuesFrom:
    - kind: ConfigMap
      name: weave-values
      valuesKey: values.yaml
YAML
}
