# Used to create the Auth0 resources for the DPE stack
resource "auth0_resource_server" "k8s-cluster-api" {
  name        = "${var.cluster_name}-api"
  identifier  = var.auth0_identifier
  signing_alg = "RS256"

  allow_offline_access = false
  # 108000 seconds = 1.25 days
  # An offset of 1.25 days allows a daily token refresh to occur by simple cronjob
  # for the services that use the token
  token_lifetime                                  = 108000
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

resource "auth0_resource_server_scopes" "k8s-cluster-scopes" {
  resource_server_identifier = auth0_resource_server.k8s-cluster-api.identifier

  scopes {
    name        = "write:telemetry"
    description = "Grants write access to telemetry data"
  }

}


resource "auth0_client_credentials" "client_secrets" {
  for_each = { for client in auth0_client.oauth2_clients : client.name => client }

  client_id             = auth0_client.oauth2_clients[each.key].id
  authentication_method = "client_secret_post"
}

resource "auth0_client_grant" "access_to_k8s_cluster" {
  for_each = { for client in var.auth0_clients : client.name => client }

  client_id = auth0_client.oauth2_clients[each.key].id
  audience  = auth0_resource_server.k8s-cluster-api.identifier
  scopes    = each.value.scopes
}
