output "k8s_stack_id" {
  value = spacelift_stack.k8s_stack.id
}

output "k8s_stack_deployments_id" {
  value = spacelift_stack.k8s_stack_deployments.id
}