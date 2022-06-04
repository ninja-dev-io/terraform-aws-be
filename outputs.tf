output "databases" {
  description = "RDS data"
  value       = [for k, v in aws_db_instance.databases : { "address" : v.address, "port" : v.port, "username" : v.username }]
}

output "repository_url" {
  description = "ECR repository url"
  value       = aws_ecr_repository.ecr.repository_url
}
