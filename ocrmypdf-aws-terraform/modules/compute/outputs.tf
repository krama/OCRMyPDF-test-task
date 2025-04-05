# ECS output values
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.ocr_cluster.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.ocr_cluster.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.ocr_cluster.arn
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.ocrmypdf.id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.ocrmypdf.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.ocrmypdf.arn
}

# Lambda output values
output "file_uploader_lambda" {
  description = "Full object of the Lambda function for uploading files"
  value       = aws_lambda_function.file_uploader
}

output "file_uploader_lambda_arn" {
  description = "ARN of the Lambda function for uploading files"
  value       = aws_lambda_function.file_uploader.arn
}

output "file_uploader_lambda_name" {
  description = "Name of the Lambda function for uploading files"
  value       = aws_lambda_function.file_uploader.function_name
}

output "status_updater_lambda_arn" {
  description = "ARN of the Lambda function for updating status"
  value       = aws_lambda_function.status_updater.arn
}

output "status_updater_lambda_name" {
  description = "Name of the Lambda function for updating status"
  value       = aws_lambda_function.status_updater.function_name
}

# Autoscaling output values
output "autoscaling_target_id" {
  description = "ID of the autoscaling target group"
  value       = aws_appautoscaling_target.ocrmypdf.id
}

output "autoscaling_policy_arn" {
  description = "ARN of the autoscaling policy"
  value       = aws_appautoscaling_policy.sqs_scaling.arn
}
