output "k8s_stack_id" {
  value = spacelift_stack.k8s-stack.id
}

output "k8s_stack_deployments_id" {
  value = spacelift_stack.k8s-stack-deployments.id
}
