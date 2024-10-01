# Purpose
Create/handle ingress for the kubernetes cluster


# Integration with Auth0
Auth0 handles provisioning JWT to authenticate with the envoy gateway.

## Creating credential:
`openssl genrsa -out test_key.pem 2048`
`openssl rsa -in test_key.pem -outform PEM -pubout -out test_key.pem.pub`



Creating gateway resources:
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