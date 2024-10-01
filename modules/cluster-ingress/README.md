# Purpose
The purpose of this module is to deploy kubernetes resources related to ingress for
the cluster. Along with the ingress we will also deploy out the related SSL cert issuer.

## To implemement
The Envoy Gateway can secure ingress by verifying JWT. It can be applied to a specific
target, for example this applies it to an HTTPRoute called `backend`:

```
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: jwt-example
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: eg
  jwt:
    providers:
    - name: auth0
      remoteJWKS:
        uri: https://dev-57n3awu5je6q653y.us.auth0.com/.well-known/jwks.json
```


The HTTPRoute is used to connect the envoy gateway ingress to a service in the cluster.
In this example the path `/get` routes the request to a service called `backend` on
port 3000.
```
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: backend
spec:
  parentRefs:
    - name: eg
  rules:
    - backendRefs:
        - group: ""
          kind: Service
          name: backend
          port: 3000
          weight: 1
      matches:
        - path:
            type: PathPrefix
            value: /get
```