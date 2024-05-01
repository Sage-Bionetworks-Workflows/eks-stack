locals {
    cluster_name = "tyu-spot-ocean"
    cluster_version = "1.29"
    # This is the orca-vpc
    vpc_id = "vpc-0451035edd61bca1f"
    # These are private subnets
    subnet_ids=[
        "subnet-041a1e077243cdb07",
        "subnet-0826300f0c95283bd",
        "subnet-0b6798133e603e122",
        "subnet-04dfa7fb6a9e476d7"
    ]
    region = "us-east-1"
    eks_nodeGroup = "airflow-node-group"
    spotinst_account = "act-ac6522b4"

    tags = {
        "CostCenter" = "No Program / 000000"
    }
}

terraform {
  required_providers {
    spotinst = {
      source  = "spotinst/spotinst"
      version = "1.171.1"  # Specify the version you wish to use
    }
  }
  backend "s3" {
    bucket = "dpe-terraform-bucket"
    key    = "."
    region = "us-east-1"
  }
}

# module "oidc_github" {
#   source  = "unfunco/oidc-github/aws"
#   version = "1.8.0"

#   github_repositories = [
#     "thomasyu888/eks-stack:main"
#   ]
# }

provider "aws" {
  region = local.region
}

provider "spotinst" {
  account = local.spotinst_account
  token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_iam_role" "admin_role" {
  name = "eks_admin_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::766808016710:root"  # Replace YOUR_AWS_ACCOUNT_ID with your actual AWS account ID
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access  = true

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

  vpc_id                   = local.vpc_id
  subnet_ids               = local.subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    one = {
      name         = local.eks_nodeGroup
      desired_size = 1
      min_size     = 0
      max_size     = 10

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }
  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    SecretsManagerReadWrite = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  }
  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.admin_role.arn
      username = "admin"
      groups   = ["system:masters"]
    },
  ]

#   aws_auth_users = [
#     {
#       userarn  = local.aws_auth_users_userarn
#       username = local.aws_auth_users_username
#       groups   = local.aws_auth_users_groups
#     },
#   ]
  tags = local.tags
}

module "ocean-aws-k8s" {
  source = "spotinst/ocean-aws-k8s/spotinst"

  depends_on = [module.eks]

  # Configuration
  cluster_name                = local.cluster_name
  region                      = local.region
  subnet_ids                  = local.subnet_ids
  worker_instance_profile_arn = tolist(data.aws_iam_instance_profiles.profile.arns)[0]
  security_groups             = [module.eks.node_security_group_id]
  is_aggressive_scale_down_enabled = true
  max_scale_down_percentage = 33
  # Overwrite Name Tag and add additional
  tags = local.tags

}

module "ocean-controller" {
  source = "spotinst/ocean-controller/spotinst"

  depends_on = [module.ocean-aws-k8s]

  # Credentials.
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = local.spotinst_account

  # Configuration.
  tolerations = []
  cluster_identifier = local.cluster_name
}