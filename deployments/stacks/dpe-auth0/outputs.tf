output "auth0_clients" {
  description = "All the Auth0 clients with name, ID, and secret"
  value       = { for client in auth0_client.oauth2_clients : client.name => { id = client.id, secret = auth0_client_credentials.client_secrets[client.name].client_secret } }
  sensitive   = true
}
