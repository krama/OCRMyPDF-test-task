# Storage module variables

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "s3_force_destroy" {
  description = "Force delete S3 buckets, even if they contain objects"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "lifecycle_expiration_days" {
  description = "Number of days until temporary files are deleted in the processing directory"
  type        = number
  default     = 7
}
