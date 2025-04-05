# Output variables of the OCRMyPDF project ---------------------------------------------------

output "website_url" {
  value       = module.storage.website_url
  description = "URL of the OCRMyPDF web interface"
}

output "api_endpoint" {
  value       = module.api.api_endpoint
  description = "URL of the API endpoint for uploading PDFs"
}

output "ecr_repository_url" {
  value       = module.container.ecr_repository_url
  description = "URL of the ECR repository for container images"
}

output "sqs_queue_url" {
  value       = module.messaging.sqs_queue_url
  description = "URL of the SQS queue for processing PDFs"
}

output "sns_topic_arn" {
  value       = module.messaging.sns_topic_arn
  description = "ARN of the SNS topic for notifications"
}

output "vpc_id" {
  value       = module.networking.vpc_id
  description = "ID of the virtual private cloud (VPC)"
}

output "private_subnet_ids" {
  value       = module.networking.private_subnet_ids
  description = "IDs of the private subnets"
}

output "public_subnet_ids" {
  value       = module.networking.public_subnet_ids
  description = "IDs of the public subnets"
}

output "pdf_bucket_name" {
  value       = module.storage.pdf_bucket_id
  description = "Name of the S3 bucket for storing PDFs"
}

output "website_bucket_name" {
  value       = module.storage.website_bucket_id
  description = "Name of the S3 bucket for the web interface"
}

output "ecs_cluster_name" {
  value       = module.compute.ecs_cluster_name
  description = "Name of the ECS cluster"
}

output "ecs_service_name" {
  value       = module.compute.ecs_service_name
  description = "Name of the ECS service"
}

output "file_uploader_lambda_name" {
  value       = module.compute.file_uploader_lambda_name
  description = "Name of the Lambda function for uploading files"
}

output "status_updater_lambda_name" {
  value       = module.compute.status_updater_lambda_name
  description = "Name of the Lambda function for updating status"
}
