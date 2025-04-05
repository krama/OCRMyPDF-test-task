# Module for messaging between OCRMyPDF components

# SQS queue for processing PDF files
# Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "ocr_dlq" {
  name = "${var.prefix}-ocr-dlq-${var.environment}"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-ocr-dlq"
    }
  )
}

# Main SQS queue for processing PDF files
resource "aws_sqs_queue" "ocr_queue" {
  name                      = "${var.prefix}-ocr-queue-${var.environment}"
  delay_seconds             = var.sqs_delay_seconds
  max_message_size          = var.sqs_max_message_size
  message_retention_seconds = var.sqs_message_retention
  visibility_timeout_seconds = var.sqs_visibility_timeout
  receive_wait_time_seconds = var.sqs_receive_wait_time
  
  # Policy to redirect messages to DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ocr_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-ocr-queue"
    }
  )
}

# SNS topic for status notifications
resource "aws_sns_topic" "ocr_notifications" {
  name = "${var.prefix}-ocr-notifications-${var.environment}"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-ocr-notifications"
    }
  )
}
