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

output "private_subnet_ids" {
  value = module.sage-aws-vpc.private_subnet_ids
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
