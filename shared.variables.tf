variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = map(string)
}

variable "security_groups" {
  type = map(string)
}

variable "roles" {
  type = map(object({
    id  = string
    arn = string
  }))
}

variable "target_groups" {
  type = map(string)
}
