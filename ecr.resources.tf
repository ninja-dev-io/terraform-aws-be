resource "aws_ecr_repository" "ecr" {
  name                 = "${var.ecr.name}-${var.env}"
  image_tag_mutability = var.ecr.image_tag_mutability
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr.name
  policy     = jsonencode(var.ecr.lifecycle_policy)
}
