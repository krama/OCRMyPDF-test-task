data "archive_file" "status_updater_zip" {
  type        = "zip"
  source_file = "./lambda/file_updater.py"
  output_path = "./lambda/status_updater.zip"
}

resource "aws_lambda_function" "status_updater" {
  filename         = data.archive_file.status_updater_zip.output_path
  source_code_hash = data.archive_file.status_updater_zip.output_base64sha256
  function_name    = "${var.prefix}-status-updater-${var.environment}"
  handler          = "file_updater.handler"
  runtime          = "python3.9"
  timeout          = 10
  memory_size      = 128
  role             = aws_iam_role.lambda_status_role.arn

  environment {
    variables = {
      S3_BUCKET         = aws_s3_bucket.pdf_storage.id
      S3_WEBSITE_BUCKET = aws_s3_bucket.website.id
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
