locals {
  # Applied to every resource in this stack
  tags = {
    Purpose    = "Managed Airflow for DPE workflows"
    ManagedBy  = "Terraform"
    CostCenter = "No Program / 000000"
  }
}

# Dedicated VPC for the MWAA environment
module "vpc" {
  count = local.env.enabled ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = local.env.vpc_name
  cidr = local.env.vpc_cidr_block

  azs             = local.env.azs
  private_subnets = local.env.private_subnet_cidrs
  public_subnets  = local.env.public_subnet_cidrs

  # MWAA runs in the private subnets and needs egress to install requirements
  # and reach the AWS APIs it depends on
  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true

  # Leave the VPC's default security group as AWS creates it. MWAA uses the security group
  # created by the mwaa module
  manage_default_security_group = false

  tags = local.tags
}

# Exports the VPC IDs as <region>-<vpc_name>-<key>, the names organizations-infra
# (org-formation/710-tgw) looks up with !CopyValue to attach this VPC to the Transit Gateway.
# Renaming vpc_name or replacing the VPC needs a matching organizations-infra deploy
resource "aws_cloudformation_stack" "vpc_exports" {
  # ponytail: prod skips this until its VPC is a Transit Gateway spoke; drop the dev check then
  count = local.env.enabled && var.deployment_environment == "dev" ? 1 : 0

  name = "${local.env.vpc_name}-vpc-exports"
  template_body = jsonencode({
    # A stack needs at least one resource
    Resources = { Placeholder = { Type = "AWS::CloudFormation::WaitConditionHandle" } }
    Outputs = {
      for key, value in {
        VPCId             = module.vpc[0].vpc_id
        PrivateRouteTable = module.vpc[0].private_route_table_ids[0]
        PrivateSubnet     = module.vpc[0].private_subnets[0]
        PrivateSubnet1    = module.vpc[0].private_subnets[1]
      } : key => { Value = value, Export = { Name = "${local.env.region}-${local.env.vpc_name}-${key}" } }
    }
  })

  tags = local.tags
}

# The MWAA environment, running in the private subnets of the VPC above
module "mwaa" {
  source     = "../../../modules/mwaa"
  enabled    = local.env.enabled
  name       = local.env.name
  region     = local.env.region
  vpc_id     = one(module.vpc[*].vpc_id)
  subnet_ids = flatten(module.vpc[*].private_subnets)

  airflow_version        = local.env.airflow_version
  orca_recipes_sha       = local.orca_recipes_sha
  deployment_environment = var.deployment_environment
  dag_s3_buckets         = keys(module.config.dag_buckets[var.deployment_environment])

  tags = local.tags
}
