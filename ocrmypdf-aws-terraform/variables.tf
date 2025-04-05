# Basic variables for OCRMyPDF infrastructure

# General settings
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-2"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Value of environment must be one of: dev, staging, prod."
  }
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "ocrmypdf"
}

# Networking settings
variable "vpc_id" {
  description = "ID of existing VPC (optional, if a new one should be created)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "IDs of subnets for ECS tasks (optional, if new ones should be created)"
  type        = list(string)
  default     = []
}

variable "lambda_subnet_ids" {
  description = "IDs of subnets for Lambda functions (optional, if new ones should be created)"
  type        = list(string)
  default     = []
}

# Container settings
variable "docker_hub_image" {
  description = "Docker Hub image (optional)"
  type        = string
  default     = "krama4d/ocrmypdf:latest"
}

variable "force_delete_ecr" {
  description = "Force delete ECR repository with images"
  type        = bool
  default     = false
}

# LocalStack settings
variable "use_localstack" {
  description = "Use LocalStack for local development"
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

# API Gateway settings
variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

# Lambda settings
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

# ECS settings
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

variable "force_ecs_service" {
  description = "Force create ECS service when using LocalStack"
  type        = bool
  default     = false
}

# Autoscaling settings
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

# S3 settings
variable "s3_force_destroy" {
  description = "Force delete S3 buckets, even if they contain objects"
  type        = bool
  default     = true
}

# SQS settings
variable "sqs_visibility_timeout" {
  description = "SQS message visibility timeout in seconds"
  type        = number
  default     = 600
}

variable "sqs_message_retention" {
  description = "SQS message retention period in seconds"
  type        = number
  default     = 86400
}
