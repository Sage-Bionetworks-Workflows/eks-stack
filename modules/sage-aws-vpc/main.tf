

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = var.vpc_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs


  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    Name                     = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    Name                              = "private"
  }

  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  manage_default_security_group = true

  # default_network_acl_ingress = [
  #   {
  #     "action" : "deny",
  #     "cidr_block" : "0.0.0.0/0",
  #     "from_port" : 0,
  #     "protocol" : "-1",
  #     "rule_no" : 98,
  #     "to_port" : 0
  #   },
  #   {
  #     "action" : "deny",
  #     "from_port" : 0,
  #     "ipv6_cidr_block" : "::/0",
  #     "protocol" : "-1",
  #     "rule_no" : 99,
  #     "to_port" : 0
  #   }
  # ]

  tags = var.tags
}
