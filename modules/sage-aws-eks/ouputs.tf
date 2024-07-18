output "cluster_name" {
  value = var.cluster_name
}

output "region" {
  value = var.region
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}
