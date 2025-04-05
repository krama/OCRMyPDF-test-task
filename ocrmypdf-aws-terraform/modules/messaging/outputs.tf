# Output variables for messaging module

output "sqs_queue_id" {
  description = "ID of the main SQS queue"
  value       = aws_sqs_queue.ocr_queue.id
}

output "sqs_queue_arn" {
  description = "ARN of the main SQS queue"
  value       = aws_sqs_queue.ocr_queue.arn
}

output "sqs_queue_url" {
  description = "URL of the main SQS queue"
  value       = aws_sqs_queue.ocr_queue.url
}

output "sqs_dlq_id" {
  description = "ID of the dead letter queue"
  value       = aws_sqs_queue.ocr_dlq.id
}

output "sqs_dlq_arn" {
  description = "ARN of the dead letter queue"
  value       = aws_sqs_queue.ocr_dlq.arn
}

output "sqs_dlq_url" {
  description = "URL of the dead letter queue"
  value       = aws_sqs_queue.ocr_dlq.url
}

output "sns_topic_id" {
  description = "ID of the SNS topic for notifications"
  value       = aws_sns_topic.ocr_notifications.id
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = aws_sns_topic.ocr_notifications.arn
}
