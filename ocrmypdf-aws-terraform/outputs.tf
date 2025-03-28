output "website_url" {
  value = "http://${aws_s3_bucket.website.bucket}.s3-website-${var.region}.amazonaws.com"
  # URL of web interface
  description = "URL of the web interface"
  
  depends_on = [aws_s3_bucket.website, aws_s3_bucket_website_configuration.website]
}

output "api_endpoint" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.api_stage.stage_name}/upload"
  # API endpoint URL
  description = "Endpoint URL for the API"
  
  depends_on = [aws_api_gateway_deployment.api_deployment, aws_api_gateway_stage.api_stage]
}

output "ecr_repository_url" {
  value = aws_ecr_repository.ocrmypdf.repository_url
  # ECR repository URL
  description = "URL of the ECR repository"
  
  depends_on = [aws_ecr_repository.ocrmypdf]
}

output "sqs_queue_url" {
  value = aws_sqs_queue.ocr_queue.url
  # SQS queue URL
  description = "URL of the SQS queue"
  
  depends_on = [aws_sqs_queue.ocr_queue]
}

output "sns_topic_arn" {
  value = aws_sns_topic.ocr_notifications.arn
  # SNS topic ARN
  description = "ARN of the SNS topic"
  
  depends_on = [aws_sns_topic.ocr_notifications]
}
