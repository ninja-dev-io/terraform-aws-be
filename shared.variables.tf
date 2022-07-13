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
  type = map(string)
}

variable "target_groups" {
  type = map(string)
}
