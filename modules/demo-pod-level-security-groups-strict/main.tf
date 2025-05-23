# Requirements for pod security groups:
# They must allow inbound communication from the security group applied to your nodes (for kubelet) over any ports that you've configured probes for.
# They must allow outbound communication over TCP and UDP ports 53 to a security group assigned to the Pods (or nodes that the Pods run on) running CoreDNS. 
# The security group for your CoreDNS Pods must allow inbound TCP and UDP port 53 traffic from the security group that you specify.
# They must have necessary inbound and outbound rules to communicate with other Pods that they need to communicate with.

locals {
  security_group_policies = {
    client = {
      name      = "security-group-policy-client"
      namespace = "client"
      role      = "client"
    },
    backend = {
      name      = "security-group-policy-backend"
      namespace = "stars"
      role      = "backend"
    },
    frontend = {
      name      = "security-group-policy-frontend"
      namespace = "stars"
      role      = "frontend"
    },
    ui = {
      name      = "security-group-policy-ui"
      namespace = "management-ui"
      role      = "management-ui"
    }
  }
}

resource "aws_security_group" "sg-stars-demo" {
  name        = "${var.cluster_name}-sg-stars-demo"
  description = "Security group for EKS pod-level security for the stars demo"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all traffic to self"
  }

  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
    description     = "Allow all traffic from node for kubelet."
  }

  # ingress {
  #   #  If I had any probes like liveness or health checks I would need to explicity allow it here
  #   from_port       = 9001
  #   to_port         = 9001
  #   protocol        = "tcp"
  #   security_groups = [var.node_security_group_id]
  #   description     = "Allow all TCP traffic from the security groups"
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all traffic from self"
  }

  egress {
    from_port       = 53
    to_port         = 53
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
    description     = "Allow all TCP traffic to the node security group"
  }

  egress {
    from_port       = 53
    to_port         = 53
    protocol        = "udp"
    security_groups = [var.node_security_group_id]
    description     = "Allow all UDP traffic to the node security group"
  }

}

resource "kubernetes_manifest" "security_group_policy" {
  for_each = local.security_group_policies

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = each.value.name
      namespace = each.value.namespace
    }
    spec = {
      podSelector = {
        matchLabels = {
          role = each.value.role
        }
      }
      securityGroups = {
        groupIds = [
          aws_security_group.sg-stars-demo.id,
          var.pod_to_node_dns_sg_id,
        ]
      }
    }
  }
}

resource "kubernetes_namespace" "client" {
  metadata {
    name = "client"
  }
}

resource "kubernetes_deployment" "client-deployment" {
  metadata {
    name      = "client"
    namespace = "client"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        role = "client"
      }
    }

    template {
      metadata {
        labels = {
          role = "client"
        }
      }

      spec {
        container {
          name              = "client"
          image             = "calico/star-probe:v0.1.0"
          image_pull_policy = "Always"

          command = ["probe", "--urls=http://frontend.stars:80/status,http://backend.stars:6379/status"]

          port {
            container_port = 9000
          }
        }
      }
    }
  }

}

resource "kubernetes_service" "client-service" {
  depends_on = [kubernetes_namespace.client]
  metadata {
    name      = "client"
    namespace = "client"
  }

  spec {
    selector = {
      role = "client"
    }

    port {
      port        = 9000
      target_port = 9000
    }
  }
}

resource "kubernetes_service" "frontend-service" {
  depends_on = [kubernetes_namespace.stars-namespace]
  metadata {
    name      = "frontend"
    namespace = "stars"
  }

  spec {
    selector = {
      role = "frontend"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "frontend-deployment" {
  depends_on = [kubernetes_namespace.stars-namespace]
  metadata {
    name      = "frontend"
    namespace = "stars"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        role = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          role = "frontend"
        }
      }

      spec {
        container {
          name              = "frontend"
          image             = "calico/star-probe:v0.1.0"
          image_pull_policy = "Always"

          command = ["probe", "--http-port=80", "--urls=http://frontend.stars:80/status,http://backend.stars:6379/status,http://client.client:9000/status"]

          port {
            container_port = 80
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "backend-service" {
  depends_on = [kubernetes_namespace.stars-namespace]
  metadata {
    name      = "backend"
    namespace = "stars"
  }

  spec {
    selector = {
      role = "backend"
    }

    port {
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_deployment" "backend-deployment" {
  depends_on = [kubernetes_namespace.stars-namespace]
  metadata {
    name      = "backend"
    namespace = "stars"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        role = "backend"
      }
    }

    template {
      metadata {
        labels = {
          role = "backend"
        }
      }

      spec {
        container {
          name              = "backend"
          image             = "calico/star-probe:v0.1.0"
          image_pull_policy = "Always"

          command = ["probe", "--http-port=6379", "--urls=http://frontend.stars:80/status,http://backend.stars:6379/status,http://client.client:9000/status"]

          port {
            container_port = 6379
          }
        }
      }
    }
  }
}


resource "kubernetes_namespace" "management-ui" {
  metadata {
    name = "management-ui"
    labels = {
      "role" = "management-ui"
    }
  }
}

resource "kubernetes_service" "management-ui-service" {
  depends_on = [kubernetes_namespace.management-ui]
  metadata {
    name      = "management-ui"
    namespace = "management-ui"
  }

  spec {
    type = "LoadBalancer"

    # Setting this updates the `Source` field for the LoadBalancer security group
    load_balancer_source_ranges = var.load_balancer_source_ranges

    port {
      port        = 80
      target_port = 9001
    }

    selector = {
      role = "management-ui"
    }
  }
}

resource "kubernetes_deployment" "management-ui-deployment" {
  depends_on = [kubernetes_namespace.management-ui]
  metadata {
    name      = "management-ui"
    namespace = "management-ui"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        role = "management-ui"
      }
    }

    template {
      metadata {
        labels = {
          role = "management-ui"
        }
      }

      spec {
        container {
          name              = "management-ui"
          image             = "calico/star-collect:v0.1.0"
          image_pull_policy = "Always"

          port {
            container_port = 9001
          }
        }
      }
    }
  }
}

resource "kubernetes_namespace" "stars-namespace" {
  metadata {
    name = "stars"
  }
}
