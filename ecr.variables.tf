variable "ecr" {
  type = object({
    name                 = string
    image_tag_mutability = string
    lifecycle_policy = object({
      rules = list(object({
        rulePriority = number
        description  = string
        action = object({
          type = string
        })
        selection = object({
          tagStatus   = string
          countType   = string
          countNumber = number
        })
      }))
    })
  })
}
