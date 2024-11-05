variable "email_identities" {
  type        = list(string)
  description = "List of email identities to be added to SES"
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}
