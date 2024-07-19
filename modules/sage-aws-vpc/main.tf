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

  manage_default_security_group = false

  create_flow_log_cloudwatch_iam_role             = var.capture_flow_logs
  create_flow_log_cloudwatch_log_group            = var.capture_flow_logs
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_retention
  flow_log_cloudwatch_log_group_class             = "STANDARD"

  # Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time
  flow_log_cloudwatch_log_group_skip_destroy = false


  tags = var.tags
}
