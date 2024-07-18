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
  value = var.cidr
}

output "vpc_public_subnet_cidrs" {
  value = var.public_subnet_cidrs
}

output "vpc_private_subnet_cidrs" {
  value = var.private_subnet_cidrs
}
