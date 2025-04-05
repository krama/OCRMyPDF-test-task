# ━━━ Переменные модуля безопасности ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

variable "prefix" {
  description = "Префикс для всех ресурсов"
  type        = string
}

variable "environment" {
  description = "Окружение развертывания"
  type        = string
}

variable "vpc_id" {
  description = "ID VPC для групп безопасности"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN очереди SQS"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN темы SNS"
  type        = string
}

variable "pdf_bucket_arn" {
  description = "ARN бакета PDF"
  type        = string
}

variable "website_bucket_arn" {
  description = "ARN бакета веб-сайта"
  type        = string
}

variable "tags" {
  description = "Теги для ресурсов"
  type        = map(string)
  default     = {}
}