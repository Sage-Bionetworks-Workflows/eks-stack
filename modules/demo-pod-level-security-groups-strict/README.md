# Purpose
The purpose of this module is to show how pod level security groups can be applied to
pods running inside of an EKS cluster.


The use of network policies is recommended over the use of pod level security groups
due to the simplicity of it. However, if more strict networking requirements are needed
then a mix of both pod level security groups and network policies can be used if the
`pod_security_group_enforcing_mode` is set to `standard`. This is an option provided
on the eks module. When running in standard mode it will allow east/west traffic to be
routed according to the network policies, while traffic going in and out of the cluster
is routed according to the security groups applied to the pod.


# Why use pod level security groups
With security groups for Pods, you can improve compute efficiency by running 
applications with varying network security requirements on shared compute resources. 
Multiple types of security rules, such as Pod-to-Pod and Pod-to-External AWS services, 
can be defined in a single place with EC2 security groups and applied to workloads with 
Kubernetes native APIs.

# Limitations/Problems to solve if implemented
Granting pod level security access to a public LoadBalancer is not a fully solved task.

Background:

- When creating a `kubernetes_service` of type `LoadBalancer` the VPC CNI plugin will provision an internet facing Network Load Balancer.
- This NLB needs to be able to perform health checks as well as route traffic to the appropiate pod

Problems:
- The order of the creation of these AWS resources is a classic "Chicken & Egg" problem. The `kubernetes_service` resource does not directly export the security group that it creates, and as such cannot be used as a reference within the TF script.
- The pod level security group needs to allow inbound connections from the node security group as that is where the NLB is forwarding traffic to.

Possible solutions:
- Create the NLB ahead of time and manually attach the required listener, as well as reference it within the `kubernetes_service`.
- Don't allow anything with pod level security groups to be reachable from outside the cluster. IE: Only use it to control "backend" services.

# Implementation details
This module is implementing the stars demo detailed [here](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html).
The demo is specifically using Network Policy K8s resources and is covered in the `demo-network-policy` module. However,
this module is replacing this to look at how we would control pod->pod networking with
security groups.

The following is a guideline of the connections each security group needs to allow:

- They must allow inbound communication from the security group applied to your nodes (for kubelet) over any ports that you've configured probes for.
- They must allow outbound communication over TCP and UDP ports 53 to a security group assigned to the Pods (or nodes that the Pods run on) running CoreDNS. 
- The security group for your CoreDNS Pods must allow inbound TCP and UDP port 53 traffic from the security group that you specify.
- They must have necessary inbound and outbound rules to communicate with other Pods that they need to communicate with.


All of these items are implemented in this module by:

- When the EKS module is deployed it will create a SG named `${var.cluster_name}-pod-dns-egress` which is then added to the node SG inbound rules. This allows egress from the pod for DNS lookup.
- The SG for all pods that need to allow networking are all given the same SG.
- Not implemented, but added as a comment: Setting up the required ingress for liveness/readiness probes


# Additional reading
- <https://aws.github.io/aws-eks-best-practices/networking/sgpp/>
- <https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html>
- <https://aws.github.io/aws-eks-best-practices/networking/sgpp/#enforcing-mode-use-strict-mode-for-isolating-pod-and-node-traffic>