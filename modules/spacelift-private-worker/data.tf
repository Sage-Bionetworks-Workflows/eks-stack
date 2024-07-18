data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# This will probable be manually created in the AWS console to prevent the token from being stored in the repo
# TODO: Some more work is needed to integrate with https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html
# For an MVP this was m
# data "aws_secretsmanager_secret" "worker-pool-token" {
#   name = "spacelift_worker_pool_token"
# }
# data "aws_secretsmanager_secret" "worker-pool-private-key" {
#   name = "spacelift_worker_pool_private_key"
# }

# data "aws_secretsmanager_secret_version" "worker-pool-token-secret" {
#   secret_id = data.aws_secretsmanager_secret.worker-pool-token.id
# }

# data "aws_secretsmanager_secret_version" "worker-pool-private-key-secret" {
#   secret_id = data.aws_secretsmanager_secret.worker-pool-private-key.id
# }
