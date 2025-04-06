# Frontend module variables

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "website_bucket" {
  description = "Website bucket ID"
  type        = string
}

variable "api_endpoint" {
  description = "API Gateway endpoint URL"
  type        = string
}

variable "api_id" {
  description = "API Gateway ID"
  type        = string
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
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

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}