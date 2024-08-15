# Purpose
The purpose of this module is to show how network policies enforced by the AWS EKS CNI
plugin can be applied to pods running inside of an EKS cluster.


The use of network policies is recommended over the use of pod level security groups
due to the simplicity of it. However, if more strict networking requirements are needed
then a mix of both pod level security groups and network policies can be used if the
`pod_security_group_enforcing_mode` is set to `standard`. This is an option provided
on the eks module. When running in standard mode it will allow east/west traffic to be
routed according to the network policies, while traffic going in and out of the cluster
is routed according to the security groups applied to the pod.

# Why use network policies
K8 network policies allow for a kubernetes specific way of enforcing traffic within
the cluster. Also known as "east/west" traffic, east-west traffic refers to all network 
communication that occurs between pods within a Kubernetes cluster.


The administration of network policies is very simple and provides mechanisms for
selecting the appropriate k8 resources you want to apply the policies to.


By default, pods within a Kubernetes cluster can freely communicate with each other on 
all ports. This can be a security risk, as a compromised pod could potentially access 
sensitive data or disrupt other pods’ functionalities. Implementing Network Policies 
addresses this by enabling control over east-west traffic flows.

# Implementation details
This module implements the [stars demo](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html#network-policy-stars-demo).


This demo deploys:

- 4 kubernetes_deployment
- 3 kubernetes_namespace
- 7 kubernetes_network_policy
- 4 kubernetes_service - 1 of which creates a classic Network Load Balancer in AWS


### kubernetes_deployment
This is responsible for creating the pods that are running the demo application

### kubernetes_namespace
Create the namespace resources to deploy resources in to

### kubernetes_network_policy
This is the key item of this demo. The policies that are implemented here do a few things:

- Allow ingress and egress to the `kube-system` namespace
- Deny all non-explicitly allowed ingress/egress in the `stars` and `client` namespace
- Allow the UI to connect to pods in the `stars` and `client` NS
- Allow `frontend` to connect to `backend` 
- Allow `client` to connect to `frontend`

### kubernetes_service
The service is responsible for publishing how pods can connect to one another. In
addition the server with a load balancer creates a class Network Load Balancer in
AWS. It is connecting to the node where the pod is running for health checks of the
service. When it is healthy it will route incoming traffic to the node, then the node
will route traffic to the appropriate pod.

# Additional reading
- <https://kubernetes.io/docs/concepts/services-networking/network-policies/#prerequisites>
- <https://medium.com/@platform.engineers/network-policies-for-east-west-traffic-management-in-kubernetes-295ba620f4df>