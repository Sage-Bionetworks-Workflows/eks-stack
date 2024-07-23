module "sage-aws-eks-autoscaler" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version = "0.3.0"

  cluster_name           = var.cluster_name
  private_vpc_subnet_ids = var.private_subnet_ids
  vpc_id                 = var.vpc_id
  node_security_group_id = var.node_security_group_id
  spotinst_account       = var.spotinst_account
}



resource "kubernetes_network_policy" "default_deny" {
  for_each = toset(["stars", "client"])

  metadata {
    name      = "default-deny"
    namespace = each.value
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]
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

          command = ["probe", "--http-port=80", "--urls=http://frontend.stars:1025/status,http://backend.stars:6379/status,http://client.client:9000/status"]

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
    load_balancer_source_ranges = ["52.44.61.21/32"]

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
