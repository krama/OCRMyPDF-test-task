#  ╔═╗╔═╗ ╔═╗
#  ╚═╗║═╬╗╚═╗
#  ╚═╝╚═╝╚╚═╝

resource "aws_sqs_queue" "ocr_queue" {
  name                      = "${var.prefix}-ocr-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  visibility_timeout_seconds = 600
  receive_wait_time_seconds = 10
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ocr_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name = "${var.prefix}-ocr-queue"
  }
}

resource "aws_sqs_queue" "ocr_dlq" {
  name = "${var.prefix}-ocr-dlq-${var.environment}"
  
  tags = {
    Name = "${var.prefix}-ocr-dlq"
  }
}