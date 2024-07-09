variable "vpc_id" {
  description = "ID of the parent spacelift space"
  type        = string
}

variable "private_subnet_ids" {
  description = "ID of the parent spacelift space"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the parent spacelift space"
  type        = string
}
