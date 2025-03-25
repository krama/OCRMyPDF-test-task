#  ╔═╗╔╗╔╔═╗
#  ╚═╗║║║╚═╗
#  ╚═╝╝╚╝╚═╝

resource "aws_sns_topic" "ocr_notifications" {
  name = "${var.prefix}-ocr-notifications-${var.environment}"
  
  tags = {
    Name = "${var.prefix}-ocr-notifications"
  }
}

resource "aws_sns_topic_subscription" "status_lambda" {
  topic_arn = aws_sns_topic.ocr_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.status_updater.arn
}