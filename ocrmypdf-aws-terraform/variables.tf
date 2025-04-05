#  ╦  ╦╔═╗╦═╗╔═╗
#  ╚╗╔╝╠═╣╠╦╝╚═╗
#   ╚╝ ╩ ╩╩╚═╚═╝

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
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