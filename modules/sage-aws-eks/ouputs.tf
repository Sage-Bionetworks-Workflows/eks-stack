output "cluster_name" {
  value = var.cluster_name
}

output "region" {
  value = var.region
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "pod_to_node_dns_sg_id" {
  value = aws_security_group.pod-dns-egress.id
}

output "cluster_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
