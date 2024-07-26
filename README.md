# Purpose

This repo is used to deploy an EKS cluster to AWS. CI/CD is managed through Spacelift.

# Directory Structure
```
.:  Contains references to all the "Things" that are going to be deployed
├── common-resources: Resources that are environment independent
│   ├── contexts: Contexts that we'll attach across environments
│   └── policies: Rego policies that can be attached to 0..* spacelift stacks
├── dev: Development/sandbox environment
│   ├── spacelift: Terraform scripts to manage spacelift resources
│   │   └── dpe-sandbox: Spacelift specific resources to manage the CI/CD pipeline
│   └── stacks: The deployable cloud resources
│       ├── dpe-sandbox-k8s: K8s + supporting AWS resources
│       └── dpe-sandbox-k8s-deployments: Resources deployed inside of a K8s cluster
└── modules: Templatized collections of terraform resources that are used in a stack
    ├── apache-airflow: K8s deployment for apache airflow
    │   └── templates: Resources used during deployment of airflow
    ├── demo-network-policies: K8s deployment for a demo showcasing how to use network policies
    ├── demo-pod-level-security-groups-strict: K8s deployment for a demo showcasing how to use pod level security groups in strict mode
    ├── sage-aws-eks: Sage specific EKS cluster for AWS
    ├── sage-aws-k8s-node-autoscaler: K8s node autoscaler using spotinst ocean
    └── sage-aws-vpc: Sage specific VPC for AWS
```

This root `main.tf` contains all the "Things" that are going to be deployed. 
In this top level directory you'll find that the terraform files are bringing together 
everything that should be deployed in spacelift declerativly. The items declared in 
this top level directory are as follows:

1) A single root administrative stack that is responsible for taking each and every resource to deploy it to spacelift.
2) A spacelift space that everything is deployed under called `environment`.
3) Reference to the `terraform-registry` modules directory.
4) Reference to `common-resources` or reusable resources that are not environment specific.
5) The environment specific resources such as `dev`, `staging`, or `prod`

This structure is looking to https://github.com/antonbabenko/terraform-best-practices/tree/master/examples for inspiration.

## AWS VPC + AWS EKS
This section describes the VPC (Virtual Private Cloud) that the EKS cluster is deployed
to.

### AWS VPC

The VPC used in this project is created with the [AWS VPC Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
It contains a number of defaults for our use-case at sage. Head on over to the module
definition to learn more.

### AWS EKS

[AWS EKS](https://aws.amazon.com/eks/) is a managed kubernetes cluster that handles
many of the tasks around running a k8s cluster. On-top of it we are providing the
configurable parameters in order to run a number of workloads.

#### EKS API access
API access to the kubernetes cluster endpoint is set to `Public and private`. 

Reading:

- <https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/network_connectivity.md>

##### Public
This allows one outside of the VPC to connect via `kubectl` and related tools to 
interact with kubernetes resources. By default, this API server endpoint is public to 
the internet, and access to the API server is secured using a combination of AWS 
Identity and Access Management (IAM) and native Kubernetes Role Based Access Control 
(RBAC).

##### Private
You can enable private access to the Kubernetes API server so that all communication 
between your worker nodes and the API server stays within your VPC. You can limit the 
IP addresses that can access your API server from the internet, or completely disable 
internet access to the API server.


#### EKS VPC CNI Plugin
This section describes the VPC CNI (Container Network Interface) that is being used
within the EKS cluster. The plugin is responsible for allocating VPC IP addresses to 
Kubernetes nodes and configuring the necessary networking for Pods on each node.


#### Security groups for pods
Allows us to assign EC2 security groups directly to pods running in AWS EKS clusters.
This can be used as an alternative or in conjunction with `Kubernetes network policies`.

See `modules/demo-pod-level-security-groups-strict` for more context on how this works.

#### Kubernetes network policies
Controls network traffic within the cluster, for example pod to pod traffic.

See `modules/demo-network-policies` for more context on how this works.

Further reading:
- https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html
- https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
- https://aws.amazon.com/blogs/containers/introducing-security-groups-for-pods/
- https://kubernetes.io/docs/concepts/services-networking/network-policies/


#### EKS Autoscaler

We use spot.io to manage the nodes attached to each of the EKS cluster. This tool has
scale-to-zerio capabilities and will dynamically add or removes nodes from the cluster
depending on the required demand. The autoscaler is templatized and provided as a
terraform module to be used within an EKS stack.

Setup of spotio (Manual per AWS Account):

* Subscribe through the AWS Marketplace: <https://aws.amazon.com/marketplace/saas/ordering?productId=bc241ac2-7b41-4fdd-89d1-6928ec6dae15>
* "Set up your account" on the spotio website and link it to an existing organization
* Link the account through the AWS UI:
* Create a policy (See the JSON in the spotio UI)
* Create a role (See instructions in the spotio UI)

After this has been setup the last item is to get an API token from the spotio UI and
add it to the AWS secret manager.

* Log into the spot UI and go to <https://console.spotinst.com/settings/v2/tokens/permanent>
* Create a new Permanent token, name it `{AWS-Account-Name}-token` or similar
* Copy the token and create an `AWS Secrets Manager` Plaintext secret named `spotinst_token` with a description `Spot.io token`


#### Connecting to an EKS cluster for kubectl commands

To connect to the EKS stack running in AWS you'll need to make sure that you have
SSO setup for the account you'll be using. Once setup run the commands below:
```
# Login with the profile you're using to authenticate. For example mine is called 
# `dpe-prod-admin`
aws sso login --profile dpe-prod-admin

# Update your kubeconfig with the proper values. This is saying "Authenticate with 
# AWS using my SSO session for the profile `dpe-prod-admin`. After authenticated 
# assuming that we want to use the `role/eks_admin_role` to connect to the k8s 
# cluster". This will update your kubeconfig with permissions to access the cluster.
aws eks update-kubeconfig --region us-east-1 --name dpe-k8 --role-arn arn:aws:iam::766808016710:role/eks_admin_role --profile dpe-prod-admin
```

### Spacelift
Here are some instructions on setting up spacelift.


#### Connecting a new AWS account for cloud integration

This document describes the abbreviated process below:
<https://docs.spacelift.io/integrations/cloud-providers/aws#setup-guide>

- Create a new role and set it's name to something unique within the account, such as `spacelift-admin-role`
- Description: "Role for spacelift CICD to assume when deploying resources managed by terraform"
- Use the custom trust policy below:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::324880187172:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringLike": {
                    "sts:ExternalId": "sagebionetworks@*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::{{AWS ACCOUNT ID}}:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

- Attach a few policies to the role:
  - `PowerUserAccess`
  - Create an inline policy to allow interaction with IAM (Needed if TF is going to be creating, editing, and deleting IAM roles/policies):
```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"iam:*Role",
				"iam:*RolePolicy",
				"iam:*RolePolicies",
				"iam:*Policy",
				"iam:*PolicyVersion",
				"iam:*OpenIDConnectProvider",
				"iam:*InstanceProfile"
			],
			"Resource": "*"
		}
	]
}
```
- Add a new `spacelift_aws_integration` resources to the `common-resources/aws-integrations` directory.






### Junk notes that should not be committed:
aws sso login --profile dnt-dev-admin
aws eks update-kubeconfig --region us-east-1 --name dpe-k8-sandbox --role-arn arn:aws:iam::631692904429:role/eks-admin-role-dpe-k8-sandbox --profile dnt-dev-admin


# Checklist of things I need to get done:
- Why is the service not found, and why can the demo not all connect to eachother
- Should I implement pod level security groups?
- Should I use k8s network policies?
- Can I use the 'strict' networking rule
- Connecting to the application through the TGW instead of through the internet/public VPN IP