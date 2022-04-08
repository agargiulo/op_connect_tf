variable "prefix" {
  default = "op-conn"
}

variable "op_creds_base64" {
  type = string
}

variable "op_networking" {
  type = object({
    vpc_id  = string
    subnets = list(string)
  })
}

variable "op_alb" {
  type = object({
    inbound_cidr = list(string)
    acm_cert_arn = string
    domain       = string
    hosted_zone  = string
  })
}
