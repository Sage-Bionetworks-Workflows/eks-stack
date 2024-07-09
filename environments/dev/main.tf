resource "spacelift_space" "development" {
  name            = "development"
  parent_space_id = var.parent_space_id
  description     = "Contains all the resources to deploy out to the dev enviornment."
}

module "dpe-sandbox-spacelift" {
  source          = "./dpe-sandbox-spacelift"
  parent_space_id = spacelift_space.development.id
}
