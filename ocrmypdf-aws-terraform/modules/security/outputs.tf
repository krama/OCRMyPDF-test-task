# Output variables of security module ---------------------------------------------------------

output "lambda_upload_role_arn" {
  description = "ARN of IAM role for Lambda file uploading"
  value       = aws_iam_role.lambda_upload_role.arn
}

output "lambda_upload_role_name" {
  description = "Name of IAM role for Lambda file uploading"
  value       = aws_iam_role.lambda_upload_role.name
}

output "lambda_status_role_arn" {
  description = "ARN of IAM role for Lambda status updating"
  value       = aws_iam_role.lambda_status_role.arn
}

output "lambda_status_role_name" {
  description = "Name of IAM role for Lambda status updating"
  value       = aws_iam_role.lambda_status_role.name
}

output "ecs_execution_role_arn" {
  description = "ARN of IAM role for ECS execution"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_execution_role_name" {
  description = "Name of IAM role for ECS execution"
  value       = aws_iam_role.ecs_execution_role.name
}

output "ecs_task_role_arn" {
  description = "ARN of IAM role for ECS task"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role_name" {
  description = "Name of IAM role for ECS task"
  value       = aws_iam_role.ecs_task_role.name
}

output "security_group_lambda_id" {
  description = "ID of security group for Lambda"
  value       = aws_security_group.lambda_sg.id
}

output "security_group_ecs_id" {
  description = "ID of security group for ECS"
  value       = aws_security_group.ecs_sg.id
}
