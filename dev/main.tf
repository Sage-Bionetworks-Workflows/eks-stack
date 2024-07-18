resource "spacelift_space" "development" {
  name             = "development"
  parent_space_id  = var.parent_space_id
  description      = "Contains all the resources to deploy out to the dev enviornment."
  inherit_entities = true
}

module "dpe-sandbox-spacelift" {
  source          = "./spacelift/dpe-sandbox"
  parent_space_id = spacelift_space.development.id
}
