# Output variables for container module

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.ocrmypdf.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.ocrmypdf.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.ocrmypdf.name
}

output "ecr_repository_registry_id" {
  description = "ID of the ECR registry"
  value       = aws_ecr_repository.ocrmypdf.registry_id
}
