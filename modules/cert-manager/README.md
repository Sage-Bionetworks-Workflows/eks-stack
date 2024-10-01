# Purpose
This module is used to deploy the cert-manager helm chart. cert-manager is responsible
for creating SSL certs to use within the cluster.

Resources:

- <https://cert-manager.io/docs/installation/helm/>

## Relation to envoy-gateway
The envoy-gateway is responsible for handling ingress for the kubernetes cluster. 
cert-manager has an a integration to watch for changes to `kind: Gateway` resources to
determine when to provision SSL certs. This integration is in the `values.yaml` file
of this directory under `kind: ControllerConfiguration`.
