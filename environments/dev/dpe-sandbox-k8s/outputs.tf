output "vpc_id" {
  value = module.sage-aws-vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.sage-aws-vpc.private_subnet_ids
}

output "security_group_id" {
  value = module.sage-aws-vpc.security_group_id
}
