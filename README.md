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
│   │   └── dpe-k8s/dpe-sandbox: Spacelift specific resources to manage the CI/CD pipeline
│   └── stacks: The deployable cloud resources
│       ├── dpe-auth0: Stack used to provision and setup auth0 IDP (Identity Provider) settings
│       ├── dpe-sandbox-k8s: K8s + supporting AWS resources
│       └── dpe-sandbox-k8s-deployments: Resources deployed inside of a K8s cluster
└── modules: Templatized collections of terraform resources that are used in a stack
    ├── apache-airflow: K8s deployment for apache airflow
    │   └── templates: Resources used during deployment of airflow
    ├── argo-cd: K8s deployment for Argo CD, a declarative, GitOps continuous delivery tool for Kubernetes.
    │   └── templates: Resources used during deployment of this helm chart
    ├── cert-manager: Handles provisioning TLS certificates for the cluster
    ├── envoy-gateway: API Gateway for the cluster securing and providing secure traffic into the cluster
    ├── postgres-cloud-native: Used to provision a postgres instance
    ├── postgres-cloud-native-operator: Operator that manages the lifecycle of postgres instances on the cluster
    ├── demo-network-policies: K8s deployment for a demo showcasing how to use network policies
    ├── demo-pod-level-security-groups-strict: K8s deployment for a demo showcasing how to use pod level security groups in strict mode
    ├── sage-aws-eks: Sage specific EKS cluster for AWS
    ├── sage-aws-eks-addons: Sets up additional resources that need to be installed post creation of the EKS cluster
    ├── sage-aws-k8s-node-autoscaler: K8s node autoscaler using spotinst ocean
    ├── sage-aws-ses: AWS SES (Simple email service) setup
    ├── sage-aws-vpc: Sage specific VPC for AWS
    ├── signoz: SigNoz provides APM, logs, traces, metrics, exceptions, & alerts in a single tool
    ├── trivy-operator: K8s deployment for trivy, along with a few supporting charts for security scanning
    │   └── templates: Resources used during deployment of these helm charts
    ├── victoria-metrics: K8s deployment for victoria metrics, a promethus like tool for cluster metric collection
    │   └── templates: Resources used during deployment of these helm charts
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

## AWS VPC
The VPC used in this project is created with the [AWS VPC Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
It contains a number of defaults for our use-case at sage. Head on over to the module
definition to learn more.

## AWS EKS

[AWS EKS](https://aws.amazon.com/eks/) is a managed kubernetes cluster that handles
many of the tasks around running a k8s cluster. On-top of it we are providing the
configurable parameters in order to run a number of workloads.

### EKS API access
API access to the kubernetes cluster endpoint is set to `Public and private`. 

Reading:

- <https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/network_connectivity.md>

#### Public
This allows one outside of the VPC to connect via `kubectl` and related tools to 
interact with kubernetes resources. By default, this API server endpoint is public to 
the internet, and access to the API server is secured using a combination of AWS 
Identity and Access Management (IAM) and native Kubernetes Role Based Access Control 
(RBAC).

#### Private
You can enable private access to the Kubernetes API server so that all communication 
between your worker nodes and the API server stays within your VPC. You can limit the 
IP addresses that can access your API server from the internet, or completely disable 
internet access to the API server.


### EKS VPC CNI Plugin
This section describes the VPC CNI (Container Network Interface) that is being used
within the EKS cluster. The plugin is responsible for allocating VPC IP addresses to 
Kubernetes nodes and configuring the necessary networking for Pods on each node.


### Security groups for pods
Allows us to assign EC2 security groups directly to pods running in AWS EKS clusters.
This can be used as an alternative or in conjunction with `Kubernetes network policies`.

See `modules/demo-pod-level-security-groups-strict` for more context on how this works.

### Kubernetes network policies
Controls network traffic within the cluster, for example pod to pod traffic.

See `modules/demo-network-policies` for more context on how this works.

Further reading:
- https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html
- https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
- https://aws.amazon.com/blogs/containers/introducing-security-groups-for-pods/
- https://kubernetes.io/docs/concepts/services-networking/network-policies/


### EKS Autoscaler

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


### Connecting to an EKS cluster for kubectl commands

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
aws eks update-kubeconfig --region us-east-1 --name dpe-k8 --profile dpe-prod-admin
```

### Security and Audits in place for the EKS cluster
AWS Guard duty is being used to perform audit trails for the EKS cluster, it involves 2
components for the cluster:

1. [EKS Audit Log Monitoring](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty-eks-audit-log-monitoring.html)
2. [GuardDuty Runtime Monitoring](https://docs.aws.amazon.com/guardduty/latest/ug/runtime-monitoring-configuration.html)


The initial configuration of these is handled through the `securitycentral` IT account.
Runtime Monitoring is installed manually via terraform modules, allowing it to be torn
down when we destroy the VPC and EKS cluster.


In addition to this scanning that is in place we are also taking advantage of the
[trivy-operator](https://github.com/aquasecurity/trivy-operator), a 
"Kubernetes-native security toolkit". The use of this tool will give us regular scans
of the resources that we are deploying to the kubernetes cluster. As resources are added
trivy will spin up and add more to the existing reports. In addition 
[policy-report](https://github.com/kyverno/policy-reporter) has been installed to the
cluster to give a UI to review the results without needing to dig into kubernetes
resources. The use of these reports will be regularly reviewed as new applications are
added to the cluster, in addition the use of the SBOM (Software bill of materials) will
allow us to review for any security advisories.

### Deploying an application to the kubernetes cluster
Deployment of applications to the kubernetes cluster is handled through the combination
of terraform (.tf) scripts, spacelift (CICD tool), and ArgoCd or Flux CD (Declarative definitions 
for applications).

To start of the deployment journey the first step is to create a new terraform module
that encapsulating everything that is required to deploy any cloud resources, in
addition to defining any kubernetes specific resources that will be deployed to the
cluster.

#### Creating the terraform module
This is supplemental information to what is defined within the [modules readme](./modules/README.md)

1. Create a new directory for your module within `./modules`, it should be named after what you are deploying.
2. At a minimum you must define a `main.tf` and `versions.tf` script that define:
   1. What cloud resources you are deploying
   2. The providers required for deploying those cloud resources
3. You may also define any number of additional [files](https://opentofu.org/docs/language/files/) and [resources](https://opentofu.org/docs/language/resources/syntax/) that are specific to the module you are creating.

#### Deploying a kubernetes resource to the cluster (ArgoCD)
Deployment of applications and kubernetes specific resources to the cluster is handled
via Argo CD, which is a declarative, GitOps continuous delivery tool for Kubernetes. The
usage of this tool instead of terraform allows for continous monitoring of Kubernetes
resources to align expected state with the actual state of the cluster. It has extensive
support to deploy helm charts, and Kubernetes yaml files.

The [declarative setup for ArgoCD](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#declarative-setup)
is done through defining specific Kubernetes resources as defined in the [ArgoCD Custom Resource Definition (CRD)](https://github.com/argoproj/argo-cd/tree/master/manifests/crds).

For our use cases we will typically be creating an [Application Specification](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)
which defines a number of pointers and configuration elements for ArgoCD to deploy to
the Kubernetes cluster. In addition we are taking advantage of [Multiple Sources for an Application](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
to install public helm charts with our custom `values.yaml` files without the need to
create our own helm chart and host it in our repository. See the following [readme for a real example](./modules/apache-airflow/README.md)
we are using for deploying out `Apache Airflow` instance. 

### Access resources on the kubernetes cluster
As of August 2024 the only access to resources on the kubernetes cluster is occuring
through kubectl port forward sessions. No internet facing load balancers are avaiable
to connect to.

Using a tool like `K9s` navigate to the pod in question and start a port forward session.
Then open up a browser and go to the `localhost` and port you have specified in your
port forward session. 

(Area of future work to have better secrets management): https://sagebionetworks.jira.com/browse/IBCDPE-1038

Most, but not all, resources will have a login page where you'll
need to enter in a username and password. These resources will have a Kubernetes secret
in base64 that you'll be able to look at and get the appropriate username/password to
log into the tool. Once you obtain the Base64 data you'll need to decode it and then 
log into the tool. Examples:

- ArgoCD: Secret is named `argocd-initial-admin-secret` with a default username of `admin`
- Grafana: Secret is named `victoria-metrics-k8s-stack-grafana` with a default username of `admin`

## Tear down of EKS stacks
If you need to fully tear down all of the infra start at the smallest point and work
outwards. Destroy items in this order:

- Go into the argoCD UI and delete all applications
- Run `tofu destroy --auto-approve` as a task in spacelift for the Kubernetes Deployments stack
- Run `tofu destroy --auto-approve` as a task in spacelift for the infrastructure deployment stack

## Spacelift
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
				"iam:*InstanceProfile",
				"iam:ListPolicyVersions",
				"iam:ListGroupsForUser",
                "iam:ListAttachedUserPolicies"
			],
			"Resource": "*"
		},
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateUser",
                "iam:AttachUserPolicy",
                "iam:ListPolicies",
                "iam:TagUser",
                "iam:GetUser",
                "iam:DeleteUser",
                "iam:CreateAccessKey",
                "iam:ListAccessKeys",
                "iam:DeleteAccessKey"
            ],
            "Resource": "arn:aws:iam::{{AWS ACCOUNT ID}}:user/smtp_user"
        }
	]
}
```
- Add a new `spacelift_aws_integration` resources to the `common-resources/aws-integrations` directory.

