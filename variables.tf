variable "prefix" {
  description = "Prefix for various resource names"
  default     = "op-conn"
}

variable "op_creds_base64" {
  description = "Base64 encoded 1password-credentials.json file"
  type        = string
}

variable "op_networking" {
  description = "Networking items, for ALB and ECS Service"
  type = object({
    vpc_id  = string
    subnets = list(string)
  })
}

variable "op_alb" {
  description = "Options for the Application Load Balancer"
  type = object({
    inbound_cidr = list(string)
    acm_cert_arn = string
    domain       = string
    hosted_zone  = string
  })
}
