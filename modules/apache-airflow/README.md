# Purpose
The purpose of this module is to deploy the `Apache Airflow` helm chart <https://github.com/apache/airflow/tree/main/chart>.

## WARNING
**When upgrading the apache airflow instance that is deployed to kubernetes you will need
to manually kill the `airflow-redis` pod.** Why? There is a helm hook that set the
password to connect to `redis` when helm sees a change, however, the `redis` pod is not
automatically restarted. If you do not do this change all airflow components that
connect to the `redis` pod will be connecting with a new password, but `redis` is still
expecting the old password.

## What resources are being deployed through this module

First we create a namespace to deploy all of the related resources to:
```terraform
resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}
```

A secret key is also created, however, the implementation needs to be reviewed before
production: <https://github.com/apache/airflow/blob/736ebfe3fe2bd67406d5a50dacbfa1e43767d4ce/docs/helm-chart/production-guide.rst#webserver-secret-key>

Finally, we are creating the ArgoCD Resource definition for the application:
```terraform
resource "kubectl_manifest" "argo-deployment" {
  # Does not deploy the resource until the namespace is created
  depends_on = [kubernetes_namespace.airflow]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
# The name of the application in ArgoCD
  name: apache-airflow
# All ArgoCD specific resources must be deployed to the `argocd` namespace
  namespace: argocd
spec:
# The name of the project in ArgoCD to group this under
  project: default
  sources:
# The reference to the public helm chart we are deploying
  - repoURL: 'https://airflow.apache.org'
    chart: airflow
    targetRevision: 1.11.0
    helm:
      releaseName: airflow
# Reference to the next source defined below, this allows us to define out own values.yaml file
      valueFiles:
      - $values/modules/apache-airflow/templates/values.yaml
# Reference to our values.yaml file we want to use
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: main
    ref: values
# Intall this to the local cluster
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: airflow
YAML
}
```

## Accessing the web UI
An `admin` user is created for airflow via the `airflow-admin-user-secret` secret that
is added to the namespace. Decode the base64 encoded password/username and use it for
the UI.