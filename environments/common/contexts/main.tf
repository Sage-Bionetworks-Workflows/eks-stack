# infracost integration
resource "spacelift_context" "k8s-kubeconfig" {
  description = "Hooks used to set up the kubeconfig for connecting to the K8s cluster"
  name        = "Kubernetes Deployments Kubeconfig"
  space_id    = "root"

  before_init = [
    "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
  ]

  before_plan = [
    "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
  ]

  before_apply = [
    "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
  ]

  before_perform = [
    "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
  ]

  before_destroy = [
    "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
  ]
}

