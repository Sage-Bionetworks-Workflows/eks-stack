resource "spacelift_policy_attachment" "bfauble-enforce-tags-on-resources" {
  policy_id = "enforce-tags-on-resources-cli"
  # This is the Outside K8s infra stack
  stack_id  = "bfauble"
}

resource "spacelift_policy_attachment" "infrastructure-inside-eks-cluster-enforce-tags-on-resources" {
  policy_id = "enforce-tags-on-resources-cli"
  stack_id  = "infrastructure-inside-eks-cluster"
}

resource "spacelift_policy_attachment" "bfauble-cloud-spend-estimation" {
  policy_id = "cloud-spend-estimation-cli"
  # This is the Outside K8s infra stack
  stack_id  = "bfauble"
}

resource "spacelift_policy_attachment" "infrastructure-inside-eks-cluster-cloud-spend-estimation" {
  policy_id = "cloud-spend-estimation-cli"
  stack_id  = "infrastructure-inside-eks-cluster"
}