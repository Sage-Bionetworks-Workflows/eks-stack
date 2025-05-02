output "vpc_id" {
  value = module.sage-aws-vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.sage-aws-vpc.vpc_cidr_block
}

output "vpc_public_subnet_cidrs" {
  value = module.sage-aws-vpc.vpc_public_subnet_cidrs
}

output "vpc_private_subnet_cidrs" {
  value = module.sage-aws-vpc.vpc_private_subnet_cidrs
}

output "private_subnet_ids_eks_worker_nodes" {
  value = module.sage-aws-vpc.private_subnet_ids_eks_worker_nodes
}

output "vpc_security_group_id" {
  value = module.sage-aws-vpc.vpc_security_group_id
}

output "node_security_group_id" {
  value = module.sage-aws-eks.node_security_group_id
}

output "pod_to_node_dns_sg_id" {
  value = module.sage-aws-eks.pod_to_node_dns_sg_id
}

output "region" {
  value = module.sage-aws-vpc.region
}

output "cluster_name" {
  value = module.sage-aws-eks.cluster_name
}

output "cluster_oidc_provider_arn" {
  value = module.sage-aws-eks.cluster_oidc_provider_arn
}

output "smtp_user" {
  value = length(module.sage-aws-ses) > 0 ? module.sage-aws-ses[0].smtp_user : ""
}

output "smtp_password" {
  sensitive = true
  value     = length(module.sage-aws-ses) > 0 ? module.sage-aws-ses[0].smtp_password : ""
}

output "synapse_webhook_url" {
  description = "The URL to use for Synapse webhook registration"
  value       = "${module.synapse-webhook-api-gateway.api_endpoint}/create"
}
