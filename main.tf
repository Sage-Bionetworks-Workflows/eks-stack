resource "aws_iam_role" "admin_role" {
  name = "eks_admin_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::766808016710:root" # Replace YOUR_AWS_ACCOUNT_ID with your actual AWS account ID
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "spacelift-created-vpc"
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  private_subnet_tags = {
    Name = "private"
  }

  # When removing the Internet gateway it might have allocated from elastic IP addresses
  # Turn off the nat_gateway to force the IP addresses to be removed
  # > "Network vpc-0f30cfca319ebc521 has some mapped public address(es). Please unmap those public address(es) before detaching the gateway.""
  create_igw         = true
  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true

  manage_default_security_group = true
  # default_security_group_egress = []
  # default_security_group_ingress = []
  # Disable inbound rules for the default network ACL
  # TODO: Another mechanism is required. Having these rules prevents nodes from joining the cluster
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

  tags = merge(
    var.tags,
    {
      Terraform   = "true"
      Environment = "dev"
    }
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.12"
  # version = "~> 20.9"

  depends_on = [module.vpc]

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  control_plane_subnet_ids  = module.vpc.intra_subnets
  cluster_security_group_id = module.vpc.default_security_group_id


  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    one = {
      name         = var.eks_nodeGroup
      desired_size = 1
      min_size     = 0
      max_size     = 2

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
        SecretsManagerReadWrite  = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
        WorkerNodePolicy         = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      }
    }
    # ,
    # two = {
    #   name         = "seqera"
    #   desired_size = 1
    #   min_size     = 0
    #   max_size     = 10

    #   instance_types = ["t3.large"]
    #   capacity_type  = "SPOT"
    # }
  }
  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    SecretsManagerReadWrite  = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
    WorkerNodePolicy         = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API"


  access_entries = {
    # One access entry with a policy associated
    eks_admin_role = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.admin_role.arn

      policy_associations = {
        eks_admin_role = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html#access-policy-permissions
    # TODO: Additional roles that need to be created:
    # AmazonEKSAdminViewPolicy?
    # AmazonEKSEditPolicy
    # AmazonEKSViewPolicy

  }
  tags = var.tags
}

