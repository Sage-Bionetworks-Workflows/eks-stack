module "sage-aws-eks-autoscaler" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version = "0.2.2"

  cluster_name           = "dpe-k8-sandbox"
  private_vpc_subnet_ids = var.private_subnet_ids
  vpc_id                 = var.vpc_id
  node_security_group_id = var.node_security_group_id
}

# Anything beyond this is used for testing
# resource "aws_security_group" "allow_tls" {
#   name        = "allow_tls"
#   description = "Allow TLS inbound traffic and all outbound traffic"
#   vpc_id      = aws_vpc.main.id

#   tags = {
#     Name = "allow_tls"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv4         = var.vpc_cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

resource "kubernetes_namespace" "testing" {
  metadata {
    name = "testing-namespace"
  }
}

# resource "kubernetes_manifest" "security_group_policy" {
#   manifest = <<EOF
# apiVersion: vpcresources.k8s.aws/v1beta1
# kind: SecurityGroupPolicy
# metadata:
#   name: my-test-security-group-policy
#   namespace: testing-namespace
# spec:
#   podSelector: {}
#   securityGroups:
#     groupIds:
#       - my_pod_security_group_id
# EOF
# }

resource "kubernetes_manifest" "client_deployment" {
  manifest = yamldecode(<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client 
  namespace: client
spec:
  replicas: 1
  selector:
    matchLabels:
      role: client
  template:
    metadata:
      labels:
        role: client 
    spec:
      containers:
      - name: client 
        image: calico/star-probe:v0.1.0
        imagePullPolicy: Always
        command:
        - probe
        - --urls=http://frontend.stars:80/status,http://backend.stars:6379/status
        ports:
        - containerPort: 9000 
EOF
  )
}

resource "kubernetes_manifest" "client_service" {
  manifest = yamldecode(<<EOF
apiVersion: v1
kind: Service
metadata:
  name: client
  namespace: client
spec:
  ports:
  - port: 9000 
    targetPort: 9000
  selector:
    role: client 
EOF
  )
}

resource "kubernetes_manifest" "frontend_service" {
  manifest = yamldecode(<<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend 
  namespace: stars
spec:
  ports:
  - port: 80 
    targetPort: 80 
  selector:
    role: frontend 
EOF
  )
}

resource "kubernetes_manifest" "frontend_deployment" {
  manifest = yamldecode(<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend 
  namespace: stars
spec:
  replicas: 1
  selector:
    matchLabels:
      role: frontend
  template:
    metadata:
      labels:
        role: frontend 
    spec:
      containers:
      - name: frontend 
        image: calico/star-probe:v0.1.0
        imagePullPolicy: Always
        command:
        - probe
        - --http-port=80
        - --urls=http://frontend.stars:80/status,http://backend.stars:6379/status,http://client.client:9000/status
        ports:
        - containerPort: 80 
EOF
  )
}

resource "kubernetes_manifest" "backend_service" {
  manifest = yamldecode(<<EOF
apiVersion: v1
kind: Service
metadata:
  name: backend 
  namespace: stars
spec:
  ports:
  - port: 6379
    targetPort: 6379 
  selector:
    role: backend 
EOF
  )
}

resource "kubernetes_manifest" "backend_deployment" {
  manifest = yamldecode(<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend 
  namespace: stars
spec:
  replicas: 1
  selector:
    matchLabels:
      role: backend
  template:
    metadata:
      labels:
        role: backend 
    spec:
      containers:
      - name: backend 
        image: calico/star-probe:v0.1.0
        imagePullPolicy: Always
        command:
        - probe
        - --http-port=6379
        - --urls=http://frontend.stars:80/status,http://backend.stars:6379/status,http://client.client:9000/status
        ports:
        - containerPort: 6379 
EOF
  )
}


resource "kubernetes_namespace" "management-ui" {
  metadata {
    name = "management-ui "
    labels = {
      "role" = "management-ui "
    }
  }
}

resource "kubernetes_manifest" "management-ui-service" {
  manifest = yamldecode(<<EOF
apiVersion: v1
kind: Service
metadata:
  name: management-ui 
  namespace: management-ui 
spec:
  type: LoadBalancer
  ports:
  - port: 80 
    targetPort: 9001
  selector:
    role: management-ui 
EOF
  )
}

resource "kubernetes_manifest" "management-ui-deployment" {
  manifest = yamldecode(<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: management-ui 
  namespace: management-ui 
spec:
  replicas: 1
  selector:
    matchLabels:
      role: management-ui
  template:
    metadata:
      labels:
        role: management-ui 
    spec:
      containers:
      - name: management-ui 
        image: calico/star-collect:v0.1.0
        imagePullPolicy: Always
        ports:
        - containerPort: 9001
EOF
  )
}

resource "kubernetes_namespace" "stars-namespace" {
  metadata {
    name = "stars"
  }
}
