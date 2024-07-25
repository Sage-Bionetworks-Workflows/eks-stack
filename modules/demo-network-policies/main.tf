# Implementation of https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html#network-policy-stars-demo
resource "kubernetes_network_policy" "allow-kube-system" {
  for_each = toset(["stars", "client"])

  metadata {
    name      = "allow-kube-system"
    namespace = each.value
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
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

resource "kubernetes_network_policy" "allow_ui" {
  metadata {
    name      = "allow-ui"
    namespace = "stars"
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "management-ui"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "allow_ui_client" {
  metadata {
    name      = "allow-ui"
    namespace = "client"
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "management-ui"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
resource "kubernetes_network_policy" "backend_policy" {
  metadata {
    name      = "backend-policy"
    namespace = "stars"
  }

  spec {
    pod_selector {
      match_labels = {
        role = "backend"
      }
    }

    ingress {
      from {
        pod_selector {
          match_labels = {
            role = "frontend"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 6379
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "frontend_policy" {
  metadata {
    name      = "frontend-policy"
    namespace = "stars"
  }

  spec {
    pod_selector {
      match_labels = {
        role = "frontend"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "client"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 80
      }
    }

    egress {
      to {
        pod_selector {
          match_labels = {
            role = "backend"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 6379
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "client_policy" {
  metadata {
    name      = "client-policy"
    namespace = "client"
  }

  spec {
    pod_selector {
      match_labels = {
        role = "client"
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "stars"
          }
        }
        pod_selector {
          match_labels = {
            role = "frontend"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 80
      }
    }

    policy_types = ["Egress"]
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
