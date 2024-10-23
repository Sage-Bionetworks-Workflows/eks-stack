# Used to create the Auth0 resources for the DPE stack
resource "auth0_resource_server" "k8s-cluster-telemetry" {
  name        = "${var.cluster_name}-telemetry"
  identifier  = "${var.cluster_name}-telemetry"
  signing_alg = "RS256"

  allow_offline_access                            = false
  token_lifetime                                  = 86400
  skip_consent_for_verifiable_first_party_clients = true
  # https://registry.terraform.io/providers/auth0/auth0/latest/docs/resources/resource_server_scopes
  # Says to use the following, however it errors out:
  # This object has no argument, nested block, or exported attribute named "scopes".
  # lifecycle {
  #   ignore_changes = [scopes]
  # }
}

resource "auth0_client" "oauth2_clients" {
  for_each = { for client in var.auth0_clients : client.name => client }

  name        = each.value.name
  description = each.value.description
  app_type    = each.value.app_type

  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_client_grant" "access_to_k8s_cluster" {
  for_each = { for client in var.auth0_clients : client.name => client }

  client_id = auth0_client.oauth2_clients[each.key].id
  audience  = auth0_resource_server.k8s-cluster-telemetry.identifier
  scopes    = []
}
