# ╻ ╻┏━┓┏━┓┏━┓
# ┃┏┛┣━┫┣┳┛┗━┓
# ┗┛ ╹ ╹╹┗╸┗━┛

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "ocrmypdf"
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed (optional if creating new VPC)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks (optional if creating new subnets)"
  type        = list(string)
  default     = []
}

variable "lambda_subnet_ids" {
  description = "Subnet IDs for Lambda functions (optional if creating new subnets)"
  type        = list(string)
  default     = []
}

variable "docker_hub_image" {
  description = "Docker Hub image (optional)"
  type        = string
  default     = "krama4d/ocrmypdf:latest"
}

variable "force_delete_ecr" {
  description = "Whether to force delete ECR repository with images"
  type        = bool
  default     = false
}

variable "use_localstack" {
  description = "Whether to use LocalStack for local development"
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
  default     = "http://localhost:4566"
}

variable "localstack_access_key" {
  description = "LocalStack access key"
  type        = string
  default     = "test"
}

variable "localstack_secret_key" {
  description = "LocalStack secret key"
  type        = string
  default     = "test"
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
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
  description = "CPU units for ECS tasks"
  type        = string
  default     = "1024"
}

variable "ecs_memory" {
  description = "Memory for ECS tasks in MB"
  type        = string
  default     = "2048"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "force_ecs_service" {
  description = "Force create ECS service even when using LocalStack"
  type        = bool
  default     = false
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

variable "s3_force_destroy" {
  description = "Force destroy S3 buckets even if they contain objects"
  type        = bool
  default     = true
}

variable "sqs_visibility_timeout" {
  description = "Visibility timeout for SQS messages in seconds"
  type        = number
  default     = 600
}

variable "sqs_message_retention" {
  description = "Message retention period in seconds"
  type        = number
  default     = 86400
}
