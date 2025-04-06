# ━━━ API Gateway Module Variables ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

variable "file_uploader_lambda" {
  description = "Lambda function object for file uploading"
  type = object({
    function_name = string
    invoke_arn    = string
  })
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}