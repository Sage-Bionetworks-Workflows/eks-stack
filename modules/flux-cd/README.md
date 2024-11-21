# Purpose
This module is used to deploy the `Flux CD` [helm chart](https://fluxcd-community.github.io/helm-charts) to the cluster. [`Flux CD`](https://fluxcd.io/) is a GitOps tool used to manage the application lifecycle on a Kubernetes cluster. It was originally deployed because unlike `Argo CD`, it supports the use of `postRenderers` which are used to apply any additional changes to the application after it has been deployed, and were needed to be used to deploy the `clickhouse-backup` sidecar container to the `signoz` helm release. We do not plan to move all existing applications to using `Flux CD` at this time, but it is available and preferred to be used for any new applications added to the cluster.

## What resources are being deployed through this module
In addition to a `helm_release` which deploys the `Flux CD` helm chart, this module also creates a `capacitor` resource which is used as the frontend for `Flux CD`.

## Accessing the Flux CD UI
To access the `Flux CD` UI, you only need to port-forward the `capacitor` pod and access it in your browser.

# Deploying an application with Flux CD
To deploy an application with `Flux CD`, you will need to create a `HelmRepository` resource which points to the helm chart you want to deploy. In that resource definition, you will set the `apiVersion` to `source.toolkit.fluxcd.io/v1` and the `kind` to `HelmRepository`. For example (code from the `signoz` module):

```
resource "kubectl_manifest" "signoz-helm-repo" {
  depends_on = [kubernetes_namespace.signoz]

  yaml_body = <<YAML
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: signoz
  namespace: ${var.namespace}
spec:
  interval: 24h
  url: https://charts.signoz.io
YAML
}
```

In your `Deployment` or `HelmRelease` resource, you will need to add a similar configuration, for example (again from the `signoz` module):
```
resource "kubectl_manifest" "signoz-helm-release" {
  depends_on = [kubernetes_namespace.signoz]

  yaml_body = <<YAML
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: signoz
  namespace: ${var.namespace}
spec:
  interval: 10m
  chart:
    spec:
      chart: signoz
      version: '0.55.1'
      sourceRef:
        kind: HelmRepository
        name: signoz
        namespace: ${var.namespace}
      interval: 10m
      reconcileStrategy: Revision
...
YAML
}
```
