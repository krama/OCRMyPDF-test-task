data "archive_file" "status_updater_zip" {
  type        = "zip"
  source_file = "./lambda/file_updater.py"  # source file
  output_path = "./lambda/status_updater.zip"  # output path
}

resource "aws_lambda_function" "status_updater" {  # create lambda
  filename         = data.archive_file.status_updater_zip.output_path  # zip archive
  source_code_hash = data.archive_file.status_updater_zip.output_base64sha256  # zip hash
  function_name    = "${var.prefix}-status-updater-${var.environment}"  # lambda name
  handler          = "file_uploader.handler"  # handler
  runtime          = "python3.9"  # runtime
  timeout          = 10  # timeout
  memory_size      = 128  # memory size
  role             = aws_iam_role.lambda_status_role.arn  # IAM role

  environment { 
    variables = {
      S3_BUCKET         = aws_s3_bucket.pdf_storage.id  # S3 bucket
      S3_WEBSITE_BUCKET = aws_s3_bucket.website.id  # S3 website bucket
    }
  }

  dynamic "vpc_config" {
    for_each = (var.vpc_id != null || local.create_vpc) ? [1] : []
    content {
      subnet_ids = length(var.lambda_subnet_ids) > 0 ? var.lambda_subnet_ids : [  # subnet IDs
        local.create_vpc ? aws_subnet.subnets["private_1"].id : "",
        local.create_vpc ? aws_subnet.subnets["private_2"].id : ""
      ]
      security_group_ids = [aws_security_group.lambda_sg.id]  # security group
    }
  }
  
  depends_on = [
    aws_iam_role.lambda_status_role,
    aws_iam_role_policy_attachment.lambda_status_attach,
    aws_s3_bucket.pdf_storage,
    aws_s3_bucket.website,
    aws_subnet.subnets,
    aws_security_group.lambda_sg
  ]
}
