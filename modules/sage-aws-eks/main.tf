resource "aws_iam_role" "admin_role" {
  name = "eks_admin_role_${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::766808016710:root"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = var.tags
}

# resource "aws_iam_role" "viewer_role" {
#   name = "eks_viewer_role_${var.cluster_name}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:sts::766808016710:assumed-role/AWSReservedSSO_Developer_92af2c086e7e7f38/bryan.fauble@sagebase.org"
#         }
#         Action = "sts:AssumeRole"
#       },
#     ]
#   })

#   tags = var.tags
# }

resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
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
        }
        env = {
          ENABLE_POD_ENI                    = "true",
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard",
          # TODO: Turn on strict mode when we are ready to enforce it
          # POD_SECURITY_GROUP_ENFORCING_MODE = "strict",
          AWS_VPC_K8S_CNI_EXTERNALSNAT = "true"
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
    # eks_viewer_role = {
    #   kubernetes_groups = []
    #   principal_arn     = aws_iam_role.viewer_role.arn

    #   policy_associations = {
    #     eks_admin_role = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
    #       access_scope = {
    #         type = "cluster"
    #       }
    #     }
    #   }
    # }
  }
  tags = var.tags
}

# resource "kubernetes_network_policy" "default_deny" {
#   metadata {
#     name      = "default-deny"
#     namespace = "default"
#   }

#   spec {
#     pod_selector {}

#     policy_types = ["Ingress", "Egress"]
#   }
# }

# resource "kubernetes_network_policy" "allow_dns_access" {
#   metadata {
#     name      = "allow-dns-access"
#     namespace = "default"
#   }

#   spec {
#     pod_selector {}

#     policy_types = ["Egress"]

#     egress {
#       to {
#         namespace_selector {
#           match_labels = {
#             "kubernetes.io/metadata.name" = "kube-system"
#           }
#         }
#         pod_selector {
#           match_labels = {
#             "k8s-app" = "kube-dns"
#           }
#         }
#       }

#       ports {
#         protocol = "UDP"
#         port     = 53
#       }
#     }
#   }
# }

################################################################################
# Restrict traffic flow using Network Policies
################################################################################

# # Block all ingress and egress traffic within the stars namespace
# resource "kubernetes_network_policy" "default_deny_stars" {
#   metadata {
#     name      = "default-deny"
#     namespace = "stars"
#   }
#   spec {
#     policy_types = ["Ingress"]
#     pod_selector {
#       match_labels = {}
#     }
#   }
#   depends_on = [module.addons]
# }

# # Block all ingress and egress traffic within the client namespace
# resource "kubernetes_network_policy" "default_deny_client" {
#   metadata {
#     name      = "default-deny"
#     namespace = "client"
#   }
#   spec {
#     policy_types = ["Ingress"]
#     pod_selector {
#       match_labels = {}
#     }
#   }
#   depends_on = [module.addons]
# }

# # Allow the management-ui to access the star application pods
# resource "kubernetes_network_policy" "allow_ui_to_stars" {
#   metadata {
#     name      = "allow-ui"
#     namespace = "stars"
#   }
#   spec {
#     policy_types = ["Ingress"]
#     pod_selector {
#       match_labels = {}
#     }
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             role = "management-ui"
#           }
#         }
#       }
#     }
#   }
#   depends_on = [module.addons]
# }

# # Allow the management-ui to access the client application pods
# resource "kubernetes_network_policy" "allow_ui_to_client" {
#   metadata {
#     name      = "allow-ui"
#     namespace = "client"
#   }
#   spec {
#     policy_types = ["Ingress"]
#     pod_selector {
#       match_labels = {}
#     }
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             role = "management-ui"
#           }
#         }
#       }
#     }
#   }
#   depends_on = [module.addons]
# }

# # Allow the frontend pod to access the backend pod within the stars namespace
# resource "kubernetes_network_policy" "allow_frontend_to_backend" {
#   metadata {
#     name      = "backend-policy"
#     namespace = "stars"
#   }
#   spec {
#     policy_types = ["Ingress"]
#     pod_selector {
#       match_labels = {
#         role = "backend"
#       }
#     }
#     ingress {
#       from {
#         pod_selector {
#           match_labels = {
#             role = "frontend"
#           }
#         }
#       }
#       ports {
#         protocol = "TCP"
#         port     = "6379"
#       }
#     }
#   }
#   depends_on = [module.addons]
# }

# # Allow the client pod to access the frontend pod within the stars namespace
# resource "kubernetes_network_policy" "allow_client_to_backend" {
#   metadata {
#     name      = "frontend-policy"
#     namespace = "stars"
#   }

#   spec {
#     policy_types = ["Ingress"]
#     pod_selector {
#       match_labels = {
#         role = "frontend"
#       }
#     }
#     ingress {
#       from {
#         namespace_selector {
#           match_labels = {
#             role = "client"
#           }
#         }
#       }
#       ports {
#         protocol = "TCP"
#         port     = "80"
#       }
#     }
#   }

#   depends_on = [module.addons]
# }
