# Messaging module variables

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "sqs_delay_seconds" {
  description = "Delay before message becomes visible"
  type        = number
  default     = 0
}

variable "sqs_max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144  # 256 KB
}

variable "sqs_message_retention" {
  description = "Message retention period in seconds"
  type        = number
  default     = 86400  # 1 day
}

variable "sqs_visibility_timeout" {
  description = "Message visibility timeout in seconds"
  type        = number
  default     = 600  # 10 minutes
}

variable "sqs_receive_wait_time" {
  description = "Long poll wait time for messages"
  type        = number
  default     = 10  # 10 seconds
}

variable "sqs_max_receive_count" {
  description = "Maximum number of receives before sending to DLQ"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
