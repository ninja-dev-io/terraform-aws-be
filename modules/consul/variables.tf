variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster" {
  description = "Cluster arn"
  type        = string
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task."
  type        = list(string)
  default     = ["EC2", "FARGATE"]
}

variable "cpu" {
  description = "Number of cpu units used by the task."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task."
  type        = number
  default     = 512
}

variable "subnets" {
  description = "List of subnets that should be mapped"
  type        = list(string)
  default     = []
}

variable "target_group" {
  description = "Target group arn"
  type        = string
  default     = null
}

variable "security_groups" {
  description = "List of security groups that should be mapped"
  type        = list(string)
  default     = []
}

variable "lb_enabled" {
  description = "Whether to create an ALB for the server task. Useful for accessing the UI."
  type        = bool
  default     = false
}

variable "consul_image" {
  description = "Consul Docker image."
  type        = string
  default     = "public.ecr.aws/hashicorp/consul:1.12.0"
}

variable "consul_license" {
  description = "A Consul Enterprise license key. Requires consul_image to be set to a Consul Enterprise image."
  type        = string
  default     = ""
  sensitive   = true
}

variable "name" {
  description = "Name to be used on all the resources as identifier."
  type        = string
  default     = "server"
}

variable "service_discovery_namespace" {
  description = "The namespace where the Consul server service will be registered with AWS CloudMap."
  type        = string
  default     = "consul"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "launch_type" {
  description = "Launch type on which to run service. Valid values are EC2 and FARGATE."
  type        = string
  default     = "EC2"
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI. If running in public subnets this is required so that ECS can pull the Docker images."
  type        = bool
  default     = false
}

variable "tls" {
  description = "Whether to enable TLS on the server for the control plane traffic."
  type        = bool
  default     = false
}

variable "gossip_key_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the Consul gossip encryption key."
  type        = string
  default     = ""
}

variable "acls" {
  description = "Whether to enable ACLs on the server."
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Set wait_for_steady_state on the ECS service. This causes Terraform to wait for the Consul server task to be deployed."
  type        = bool
  default     = false
}
