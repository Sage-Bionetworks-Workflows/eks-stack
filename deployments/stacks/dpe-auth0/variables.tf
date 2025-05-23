variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "auth0_domain" {
  description = "Auth0 domain"
  type        = string
}

variable "auth0_client_id" {
  description = "Auth0 client ID"
  type        = string
}

variable "auth0_client_secret" {
  description = "Auth0 client secret"
  type        = string
}

variable "auth0_clients" {
  description = "List of clients to create in Auth0."
  type = list(object({
    name        = string
    description = string
    app_type    = string
    scopes      = list(string)
  }))
}

variable "auth0_identifier" {
  description = "Auth0 identifier for the created API."
  type        = string
}
