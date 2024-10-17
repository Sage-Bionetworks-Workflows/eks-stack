output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "vpc_security_group_id" {
  value = module.vpc.default_security_group_id
}

output "region" {
  value = var.region
}

output "vpc_cidr_block" {
  value = var.vpc_cidr_block
}

output "vpc_public_subnet_cidrs" {
  value = var.public_subnet_cidrs
}

output "private_subnet_ids_eks_control_plane" {
  value = slice(module.vpc.private_subnets, 0, length(var.private_subnet_cidrs_eks_control_plane))
}

output "private_subnet_ids_eks_worker_nodes" {
  value = slice(module.vpc.private_subnets, length(var.private_subnet_cidrs_eks_control_plane), length(var.private_subnet_cidrs_eks_worker_nodes))
}
