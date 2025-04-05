# Container module variables

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

variable "docker_hub_image" {
  description = "Docker Hub image to use"
  type        = string
  default     = "krama4d/ocrmypdf:latest"
}

variable "force_delete_ecr" {
  description = "Force delete ECR repository with images"
  type        = bool
  default     = false
}

variable "use_localstack" {
  description = "Use LocalStack for local development"
  type        = bool
  default     = false
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

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

