module "sage-aws-eks-autoscaler" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version = "0.1.0"

  cluster_name = "dpe-k8-sandbox"
}
