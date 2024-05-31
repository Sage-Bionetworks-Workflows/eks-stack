resource "aws_iam_role" "admin_role" {
  name = "eks_admin_role_${var.cluster_name}"

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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.12"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    # coredns = {
    #   most_recent = true
    # }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # TODO When the cluster is created we need to set the gp2 storageclass as default:
    # kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    # This way any PVC that is created will use gp2 as the default storage class
    # aws-ebs-csi-driver = {
    #   most_recent = true
    # }
  }
# TODO: The AWS EBS CSI driver is not working right for some reason. PVC are made, but storage is not being allocated. Determine why
  vpc_id                    = data.aws_vpc.selected.id
  subnet_ids                = data.aws_subnets.private.ids
  # TODO
  # control_plane_subnet_ids  = data.vpc.intra_subnets module.vpc.intra_subnets
  cluster_security_group_id = data.aws_security_group.vpc.id

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

