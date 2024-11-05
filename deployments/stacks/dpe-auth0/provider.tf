# Requires manually setting id and secret in the stack environment variables in the Spacelift UI
# These come from auth0 > Applications > Applications > API Explorer Application > Settings
# TF_VAR_auth0_client_id
# TF_VAR_auth0_client_secret
# TF_VAR_auth0_domain
provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_client_id
  client_secret = var.auth0_client_secret
}