locals {
  tags = {
    Purpose    = "Managed Airflow for DPE workflows"
    ManagedBy  = "Terraform"
    CostCenter = "No Program / 000000"
  }
}

module "vpc" {
  count = var.enabled ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # MWAA runs in the private subnets and needs egress to install requirements
  # and reach the AWS APIs it depends on
  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true

  manage_default_security_group = false

  tags = local.tags
}

module "mwaa" {
  source     = "../../../modules/mwaa"
  enabled    = var.enabled
  name       = var.name
  region     = var.region
  vpc_id     = one(module.vpc[*].vpc_id)
  subnet_ids = flatten(module.vpc[*].private_subnets)

  tags = local.tags
}
