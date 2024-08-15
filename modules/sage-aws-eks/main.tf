locals {
  eks_admin_roles            = tolist(data.aws_iam_roles.administrator-roles.arns)
  eks_developer_viewer_roles = tolist(data.aws_iam_roles.developer-roles.arns)

  eks_admin_role_entries = {
    for idx, role_arn in zipmap(range(length(local.eks_admin_roles)), local.eks_admin_roles) :
    "eks_admin_role_${idx}" => {
      kubernetes_groups = []
      principal_arn     = role_arn

      policy_associations = {
        eks_admin_role = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_developer_viewer_role_entries = {
    for idx, role_arn in zipmap(range(length(local.eks_developer_viewer_roles)), local.eks_developer_viewer_roles) :
    "eks_developer_viewer_role_${idx}" => {
      kubernetes_groups = []
      principal_arn     = role_arn

      policy_associations = {
        eks_developer_viewer_role = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  combined_access_entries = merge(local.eks_admin_role_entries, local.eks_developer_viewer_role_entries)
}

resource "aws_security_group" "pod-dns-egress" {
  name        = "${var.cluster_name}-pod-dns-egress"
  description = "Allow egress on port 53 for DNS queries."
  vpc_id      = var.vpc_id

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
    description = "Allow all TCP traffic to the node security group"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.private_subnet_cidrs
    description = "Allow all UDP traffic to the node security group"
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.12"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      # Derived from https://github.com/aws/amazon-vpc-cni-k8s/blob/master/charts/aws-vpc-cni/values.yaml
      configuration_values = jsonencode({
        enableNetworkPolicy = "true",
        init = {
          env = {
            DISABLE_TCP_EARLY_DEMUX = "true"
          }
        }
        nodeAgent = {
          enablePolicyEventLogs = var.enable_policy_event_logs ? "true" : "false"
          enableCloudWatchLogs  = var.capture_cloudwatch_logs ? "true" : "false"
        }
        env = {
          ENABLE_POD_ENI                    = "true",
          POD_SECURITY_GROUP_ENFORCING_MODE = var.pod_security_group_enforcing_mode,
          ENABLE_PREFIX_DELEGATION          = "true",
      } })
    }
  }

  vpc_id                    = var.vpc_id
  subnet_ids                = var.private_vpc_subnet_ids
  control_plane_subnet_ids  = var.private_vpc_subnet_ids
  cluster_security_group_id = var.vpc_security_group_id

  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    SecretsManagerReadWrite  = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
    WorkerNodePolicy         = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    VPCResourceController    = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API"

  cloudwatch_log_group_retention_in_days = var.cloudwatch_retention
  create_cloudwatch_log_group            = var.capture_cloudwatch_logs

  node_security_group_additional_rules = {
    pod_dns_ingress_tcp = {
      type                     = "ingress"
      description              = "Allow ingress on port 53 for DNS queries to the node security group"
      from_port                = 53
      to_port                  = 53
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.pod-dns-egress.id
    }
    pod_dns_ingress_udp = {
      type                     = "ingress"
      description              = "Allow ingress on port 53 for DNS queries to the node security group"
      from_port                = 53
      to_port                  = 53
      protocol                 = "udp"
      source_security_group_id = aws_security_group.pod-dns-egress.id
    }
  }


  access_entries = local.combined_access_entries

  tags = var.tags
}
