# Lambda functions for OCRMyPDF

# Zip the code for the Lambda function for file uploading
data "archive_file" "file_uploader_zip" {
  type        = "zip"
  source_file = "${path.module}/files/file_uploader.py"
  output_path = "${path.module}/files/file_uploader.zip"
}

# Lambda function for file uploading
resource "aws_lambda_function" "file_uploader" {
  filename         = data.archive_file.file_uploader_zip.output_path
  source_code_hash = data.archive_file.file_uploader_zip.output_base64sha256
  function_name    = "${var.prefix}-file-uploader-${var.environment}"
  handler          = "file_uploader.handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  role             = var.lambda_upload_role_arn

  environment {
    variables = {
      S3_BUCKET     = var.pdf_bucket_id
      SQS_QUEUE_URL = var.sqs_queue_url
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.private_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [var.security_group_lambda]
    }
  }
  
}

# Zip the code for the Lambda function for status updating
data "archive_file" "status_updater_zip" {
  type        = "zip"
  source_file = "${path.module}/files/file_updater.py"
  output_path = "${path.module}/files/status_updater.zip"
}

# Lambda function for status updating
resource "aws_lambda_function" "status_updater" {
  filename         = data.archive_file.status_updater_zip.output_path
  source_code_hash = data.archive_file.status_updater_zip.output_base64sha256
  function_name    = "${var.prefix}-status-updater-${var.environment}"
  handler          = "file_updater.handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  role             = var.lambda_status_role_arn

  environment {
    variables = {
      S3_BUCKET         = var.pdf_bucket_id
      S3_WEBSITE_BUCKET = var.website_bucket_id
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.private_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [var.security_group_lambda]
    }
  }
  
}

# Allow SNS to call the Lambda function for status updating
resource "aws_lambda_permission" "sns_status_updater" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status_updater.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

# Subscribe the Lambda function to the SNS topic
resource "aws_sns_topic_subscription" "status_lambda" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.status_updater.arn
}
