# Purpose
Create/handle ingress (aka north/south traffic) for the kubernetes cluster. Using
kubernetes resources we can define how to handle traffic.

## Components

- ClusterIssuer: Used to handle issuing SSL certificates from self or cert-manager
- EnvoyProxy: Configuration to apply to the GatewayClass
- GatewayClass: GatewayClass describes a class of Gateways available to the user for creating Gateway resources.
- Gateway: Gateway represents an instance of a service-traffic handling infrastructure by binding Listeners to a set of IP addresses.
- SecurityPolicy: Used to require that JWT authentication is provided at the Gateway from an approved list of public JWK urls.
- ClientTrafficPolicy: Configuration to apply to the Gateway. In this case it restricts TLS to use 1.3 (Latest)

## How this exposes traffic to a pod
For our deployment model we are using a single GatewayClass and a single Gateway Controller.
This deployment allows us to take advantage of using a single hostname to expose traffic
to the world using a single DNS record. It also means that we are provisioning a single
load balancer in AWS.


We are taking advantage of the `ReferenceGrant` resource: <https://gateway-api.sigs.k8s.io/api-types/referencegrant/>
to make this happen. When an application needs to expose itself out to the internet the
application will need to create 2 resources:

1) An `HTTPRoute`: <https://gateway-api.sigs.k8s.io/api-types/httproute/> which is used for specifying routing behavior of HTTP requests from a Gateway listener to a `Service`.
2) A `ReferenceGrant` <https://gateway-api.sigs.k8s.io/api-types/referencegrant/> which is used to enable cross namespace references within Gateway API. In particular, Routes may forward traffic to backends in other namespaces.

For the above 2 resources the placement of them into the correct namespaces is required
for all permissions to work. The `HTTPRoute` exists within the namespace that this
module is deployed into. The `ReferenceGrant` is deployed into the namespace that is
exposing itself to the internet. The usage of this model prevents the gateway from
forwarding traffic to namespaces or services which have not explicitly allowed traffic.


