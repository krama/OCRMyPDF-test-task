data "archive_file" "file_uploader_zip" {
  type        = "zip"
  source_file = "./lambda/file_uploader.py"
  output_path = "./lambda/file_uploader.zip"
}

resource "aws_lambda_function" "file_uploader" {
  filename         = data.archive_file.file_uploader_zip.output_path
  source_code_hash = data.archive_file.file_uploader_zip.output_base64sha256
  function_name    = "${var.prefix}-file-uploader-${var.environment}"
  handler          = "file_uploader.handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.lambda_upload_role.arn

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.pdf_storage.id
      SQS_QUEUE_URL = aws_sqs_queue.ocr_queue.id
    }
  }

  dynamic "vpc_config" {
    for_each = (var.vpc_id != null || (length(aws_vpc.main) > 0 && aws_vpc.main[0].id != "")) ? [1] : []
    content {
      subnet_ids         = length(var.lambda_subnet_ids) > 0 ? var.lambda_subnet_ids : [
        aws_subnet.private_subnet_1[0].id,
        aws_subnet.private_subnet_2[0].id,
      ]
      security_group_ids = [aws_security_group.lambda_sg.id]
    }
  }
}
