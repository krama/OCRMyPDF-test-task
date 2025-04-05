variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

variable "ecs_cpu" {
  description = "ECS task CPU units"
  type        = string
  default     = "1024"
}

variable "ecs_memory" {
  description = "ECS task memory in MB"
  type        = string
  default     = "2048"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for autoscaling"
  type        = number
  default     = 10
}

variable "target_sqs_messages_per_task" {
  description = "Target number of SQS messages per task for autoscaling"
  type        = number
  default     = 10
}

variable "docker_hub_image" {
  description = "Docker Hub image for ECS tasks"
  type        = string
}

# Resources from other modules
variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "sqs_queue_url" {
  description = "SQS queue URL"
  type        = string
}

variable "sqs_queue_name" {
  description = "SQS queue name"
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  description = "SNS topic ARN"
  type        = string
}

variable "pdf_bucket_id" {
  description = "PDF bucket ID"
  type        = string
}

variable "website_bucket_id" {
  description = "Website bucket ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# IAM roles
variable "lambda_upload_role_arn" {
  description = "ARN of IAM role for Lambda file uploading"
  type        = string
}

variable "lambda_status_role_arn" {
  description = "ARN of IAM role for Lambda status updating"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of IAM role for ECS task execution"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of IAM role for ECS tasks"
  type        = string
}

# Security groups
variable "security_group_lambda" {
  description = "ID of security group for Lambda"
  type        = string
}

variable "security_group_ecs" {
  description = "ID of security group for ECS"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
