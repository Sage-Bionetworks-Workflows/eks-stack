# Purpose
This is meant to be a small workshop that explores deploying a hello world application
to the AWS EKS Kubernetes cluster, as well as exploring a few items available within
the cluster.

## Pre-Requisites
- Access to the AWS account that an EKS cluster is deployed to. In this workshop we will assume you are using the `org-sagebase-dnt-dev` account.
- You will need either `Administrator` or `Developer` access in the related AWS account. Both will have a level of access to the EKS cluster. In this workshop we are assuming the use of `Administrator` access.
- Install a tool to access the cluster in a user friendly way such as: https://k9scli.io/
- Set up a SSO login session to access the cluster and login, for example: https://sagebionetworks.jira.com/wiki/spaces/IT/pages/2632286259/AWS+SSM+Session+Manager#%5CuD83D%5CuDCD8-Log-in-to-an-AWS-account
  - `aws sso login --profile dnt-dev-admin`
  - `aws sso login --profile dnt-dev-developer`
- Update your [kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) to connect to the cluster. The kubeconfig in this case is referring to the authentication mechanism used to access the cluster.:
    - `aws eks update-kubeconfig --region us-east-1 --name dpe-k8-sandbox --profile dnt-dev-admin`
    - `aws eks update-kubeconfig --region us-east-1 --name dpe-k8-sandbox --profile dnt-dev-developer`
- In your cli start k9s
    - `k9s`

If everything is correct you should see a screen like:
![k9s header](./workshop-resources/k9s-header.png)


### Deploying the resources through ArgoCD (Recommended)
Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes. What this
means is that it will take care of all the deployment of the resources for you. For our
use case we will be creating an 
[Application Specification](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/).
This Application Specification defines a number of pointers and configuration elements
for ArgoCD to deploy to the Kubernetes cluster. Once ArgoCD has deployed the resources
you can view the resources in the ArgoCD UI, as well as in the k9s UI.


- Create a new branch in git to push your changes to, for example `ibcdpe-1-branch-name`
- Open up `deployments/stacks/dpe-k8s-deployments/main.tf`
  - You'll notice a bunch of modules. These are the resources we are already deploying to the kubernetes cluster, wrapped in something called a "module"
  - For this tutorial we will create the resource files directly here for simplicity

- Create 3 sections in the file:

1) A locals block: <https://www.terraform.io/docs/configuration/locals.html> to organize our inputs

```terraform
locals {
  my_branch_name = "ibcdpe-1-branch-name"
  my_namespace_name = "my-cool-namespace"
  my_application_name_in_argocd = "my-cool-application"
}
```

2) A namespace: <https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>

Update `my-cool-namespace-resource` to whatever value you'd like. In this
case `my-cool-namespace-resource` is the identifier in which terraform is referencing this specific
resource.

```terraform
resource "kubernetes_namespace" "my-cool-namespace-resource" {
  metadata {
    name = local.my_namespace_name
  }
}
```

3) An Argo CD Application: <https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/>

Make sure that `depends_on = [kubernetes_namespace.my-cool-namespace-resource]` is
referencing the name of the `kubernetes_namespace` resource you just created.

```terraform
resource "kubectl_manifest" "my-argocd-application" {
  depends_on = [kubernetes_namespace.my-cool-namespace-resource]

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${local.my_application_name_in_argocd}
  namespace: argocd
spec:
  project: default
  syncPolicy:
    automated:
      prune: true
  sources:
  - repoURL: 'https://github.com/Sage-Bionetworks-Workflows/eks-stack.git'
    targetRevision: ${local.my_branch_name}
    path: deployments/stacks/dpe-k8s-deployments
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${local.my_namespace_name}
YAML
}
```

- Finally let's create a `.yaml` file within `deployments/stacks/dpe-k8s-deployments` that
defines the kubernetes resources you want to deploy.
- Create a new file named `deployments.yaml` in the folder `deployments/stacks/dpe-k8s-deployments`
  - The exact name of the file does not matter, but it should end in `.yaml`
- In our case we are creating a Deployment: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>
- Add the following to the body of the yaml file:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-helloworld
  labels:
    app: flask-helloworld
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask-helloworld
  template:
    metadata:
      labels:
        app: flask-helloworld
    spec:
      containers:
      - name: flask
        image: digitalocean/flask-helloworld:latest
        ports:
        - containerPort: 5000
```


#### Explanation of the above

You are deploying a CR (Custom Resource) to the kubernetes cluster. This tells ArgoCD
that you are deploying a set of kubernetes resources. By setting `syncPolicy` 
to `automated`, ArgoCD will take care of the deployment of the resources to the
kubernetes cluster. [sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
is an ArgoCD concept that allows you to point at one or more locations that ArgoCD will
look at in order to create the resources. In our case we are telling ArgoCD to look
at the `deployments/stacks/dpe-k8s-deployments` folder in the `eks-stack` repo for
the `targetRevision` that we specify. In our case we are setting it to the name of our
branch that we created earlier.

### Deploying the resources directly to kubernetes (Not recommended, but possible)
If you've already completed the steps above, you can skip to the next section.

- Create a new branch in git to push your changes to
- Open up `deployments/stacks/dpe-k8s-deployments/main.tf`
  - You'll notice a bunch of modules. These are the resources we are already deploying to the kubernetes cluster, wrapped in something called a "module"
  - For this tutorial we will create the resource files directly here for simplicity

- Create 2 sections in the file:

1) A namespace: <https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>

Update `my-cool-namespace-resource` and `my-cool-namespace` to whatever values you'd like. In this
case `my-cool-namespace-resource` is the identifier in which terraform is referencing this specific
resource. `my-cool-namespace` on the otherhand is the name of the namespace you'll be
creating within the kubernetes cluster.

```terraform
resource "kubernetes_namespace" "my-cool-namespace-resource" {
  metadata {
    name = "my-cool-namespace"
  }
}
```

2) A Deployment: <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>

You'll want to update the reference to your terraform namespace resource here:

- If you updated the terraform identifier `my-cool-namespace-resource` to something else, make sure they match
```terraform
resource "kubectl_manifest" "my-deployment" {
  depends_on = [kubernetes_namespace.my-cool-namespace-resource]

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: ${kubernetes_namespace.my-cool-namespace-resource.metadata.0.name}
  name: flask-helloworld
  labels:
    app: flask-helloworld
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask-helloworld
  template:
    metadata:
      labels:
        app: flask-helloworld
    spec:
      containers:
      - name: flask
        image: digitalocean/flask-helloworld:latest
        ports:
        - containerPort: 5000
YAML
}
```

- Commit the changes and push the changes to github
- Create a pull request to main
- In the git checks that run you'll see a section that says something like: `spacelift/dpe-dev-kubernetes-deployments — 2 to add, 6 to change, 0 to destroy`

![Github check](./workshop-resources/github-check.png)

- Click on `Details` and on the next screen `Deploy`
- A job will be kicked off and run within Spacelift to deploy the resources. This takes a few minutes.

### Verifying your deployed resources on the kubernetes cluster

- Inside of `k9s` check that your namespace exists `:ns`
- Check that your deployment is there `:deployments`
- Finally let's port-forward to the pod that was created `:pods`
- Navigate to the pod in your namespace and use `shift + f` to start a port forward session
- Open a web browser and go to `localhost:5000` and verify you may see `Hello, World!`


That's it! You've deployed a resource to our kubernetes cluster!

**Note:** Terraform runs from other people may cause your resources to be unexpectedly 
deleted or removed. This is intentional and expected as the state you introduced into
terraform would not be present anywhere else except for your git branch.


## Extra-credit
There are several other monitoring applications deployed to the cluster that give us
information about the cluster health.

**Tip:** You can use `/` to filter by a string within the `k9s` UI.

### argo-cd
- Find the pod named `argocd-server-` that exists within the `argocd` namespace and start a port-forward session.
- Open your web browser and connect to localhost on the port you configured. You may need to accept the self-sign SSL certificate.
- You'll be redirected to a login page so you'll need to find the credentials to log in.
- Go back to k9s and go to `:secrets`
- Find a secret named `argocd-initial-admin-secret` and click `y` to view the YAML definition of the file.
- Copy the `password` base64 encoded value and decode that base64 string. For example `echo asdf | base64 --decode`
- With the password and the username of `admin` you'll be able to log into argoCD
- Here you will see the ArgoCD applications that are deployed to the cluster. And if everything went well you'll find your `hello-world` application

### policy-reporter-ui

- Find the pod named `policy-reporter-ui-` that exists within the `trivy-system` namespace and start a port-forward session.

Here you'll see any security reports and audits that have been flagged by a tool called
`trivy`

### Grafana
Grafana is a dash boarding tool with several pre-built dashboards. It works in
conjunction with `victoria-metrics` to scrape metrics from the cluster and applications.

- Find the pod named `victoria-metrics-k8s-stack-grafana-` and start a port-forward session.
- You'll be redirected to a login page so you'll need to find the credentials to log in.
- Go back to k9s and go to `:secrets`
- Find a secret named `victoria-metrics-k8s-stack-grafana` and click `y` to view the YAML definition of the file.
- Copy the `admin-password` base64 encoded value and decode that base64 string. For example `echo asdf | base64 --decode`
- With the password and the username of `admin` you'll be able to log into grafana
- Go to `Dashboards` on the left side and see what is available. A few dashboards with interesting information are:
  - `Kubernetes / Views / Global`
  - `Kubernetes / Views / Pods`
  - `Kubernetes / System / CoreDNS`
  - `Trivy Operator Dashboard`
