# Purpose
Create/handle ingress (aka north/south traffic) for the kubernetes cluster. Using
kubernetes resources we can define how to handle traffic.

## Components
The following show some example components for creating a GatewayClass/Gateway to
handle ingress for the kubernetes cluster. This is set to use letsencrypt staging, but
it is subject to change:

```
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: "bryan.fauble@sagebase.org"
    privateKeySecretRef:
      name: letsencrypt-staging-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
          - kind: Gateway
            name: eg
            namespace: envoy-gateway
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
  gatewayClassName: eg
  listeners:
  - name: https
    protocol: HTTPS
    hostname: aff3f8141f88b4f958400fc7bab55329-385678462.us-east-1.elb.amazonaws.com
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: eg-https
  - name: http
    protocol: HTTP
    port: 80

```






