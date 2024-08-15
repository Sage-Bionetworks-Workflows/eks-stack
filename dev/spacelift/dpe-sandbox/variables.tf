variable "parent_space_id" {
  description = "ID of the parent spacelift space"
  type        = string
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}

variable "admin_stack_id" {
  description = "ID of the admin stack"
  type        = string
}
