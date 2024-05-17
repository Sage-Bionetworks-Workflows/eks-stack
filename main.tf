
# module "oidc_github" {
#   source  = "unfunco/oidc-github/aws"
#   version = "1.8.0"

#   github_repositories = [
#     "thomasyu888/eks-stack:main"
#   ]
# }

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
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# module "eks_auth" {
#   source = "aidanmelen/eks-auth/aws"
#   eks    = module.eks

#   map_roles = [
#     {
#         rolearn  = aws_iam_role.admin_role.arn
#         username = "admin"
#         groups   = ["system:masters"]
#     },
#   ]

#   map_users = [
#     {
#       userarn  = "arn:aws:sts::766808016710:assumed-role/AWSReservedSSO_Administrator_e1acc9f84863534e/thomas.yu@sagebase.org"
#       username = "user1"
#       groups   = ["system:masters"]
#     },
#     # {
#     #   userarn  = "arn:aws:iam::66666666666:user/user2"
#     #   username = "user2"
#     #   groups   = ["system:masters"]
#     # },
#   ]
#   map_accounts = [
#     "766808016710"
#   ]
# }

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

  enable_nat_gateway = true
  enable_vpn_gateway = true
  single_nat_gateway = true

  tags = merge(
    var.tags,
    {
      Terraform   = "true"
      Environment = "dev"
    }
  )
}

import {
  to = aws_eks_access_entry.spacelift_admin_role
  id = "${var.cluster_name}:arn:aws:iam::766808016710:role/spacelift_admin_role"
}

import {
  to = aws_eks_access_entry.eks_admin_role
  id = "${var.cluster_name}:arn:aws:iam::766808016710:role/eks_admin_role"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.10"
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
  cluster_security_group_id = module.vpc.default_security_group_id


  # EKS Managed Node Group(s)
  # eks_managed_node_group_defaults = {
  #   instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  # }

  # eks_managed_node_groups = {
  #   one = {
  #     name         = var.eks_nodeGroup
  #     desired_size = 1
  #     min_size     = 0
  #     max_size     = 10

  #     instance_types = ["t3.large"]
  #     capacity_type  = "SPOT"
  #     iam_role_additional_policies = {
  #       AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
  #       SecretsManagerReadWrite  = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  #     }
  #   }
  #   # ,
  #   # two = {
  #   #   name         = "seqera"
  #   #   desired_size = 1
  #   #   min_size     = 0
  #   #   max_size     = 10

  #   #   instance_types = ["t3.large"]
  #   #   capacity_type  = "SPOT"
  #   # }
  # }
  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    SecretsManagerReadWrite  = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API"


  access_entries = {
    # One access entry with a policy associated
    eks_admin_role = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::766808016710:role/eks_admin_role"

      policy_associations = {
        eks_admin_role = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    spacelift_admin_role = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::766808016710:role/spacelift_admin_role"

      policy_associations = {
        spacelift_admin_role = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  tags = var.tags
}


# ## Create additional Ocean Virtual Node Group (launchspec) ##
# module "ocean-aws-k8s-vng_gpu" {
#   source = "spotinst/ocean-aws-k8s-vng/spotinst"

#   name = "seqera"  # Name of VNG in Ocean
#   ocean_id = module.ocean-aws-k8s.ocean_id
#   subnet_ids = var.subnet_ids

#   iam_instance_profile = tolist(data.aws_iam_instance_profiles.profile2.arns)[0]
#   # instance_types = ["g4dn.xlarge","g4dn.2xlarge"] # Limit VNG to specific instance types
#   # spot_percentage = 50 # Change the spot %
#   tags = {
#     "kubernetes.io/cluster/tyu-spot-ocean" = "owned"
#   }

# }

# module "ocean-controller" {
#   source = "spotinst/ocean-controller/spotinst"

#   depends_on = [module.ocean-aws-k8s]

#   # Credentials.
#   spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
#   spotinst_account = var.spotinst_account

#   # Configuration.
#   tolerations = []
#   cluster_identifier = var.cluster_name
#   # config_map_name = module.eks_auth
# }


