#  ╔═╗╦ ╦╔╦╗╔═╗╦ ╦╔╦╗╔═╗
#  ║ ║║ ║ ║ ╠═╝║ ║ ║ ╚═╗
#  ╚═╝╚═╝ ╩ ╩  ╚═╝ ╩ ╚═╝

output "website_url" {
  value = "http://${aws_s3_bucket.website.bucket}.s3-website-${var.region}.amazonaws.com"
  description = "URL of the web interface"
}

output "api_endpoint" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/upload"
  description = "Endpoint URL for the API"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.ocrmypdf.repository_url
  description = "URL of the ECR repository"
}

output "sqs_queue_url" {
  value = aws_sqs_queue.ocr_queue.url
  description = "URL of the SQS queue"
}

output "sns_topic_arn" {
  value = aws_sns_topic.ocr_notifications.arn
  description = "ARN of the SNS topic"
}