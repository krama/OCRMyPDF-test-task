# ━━━ Local Variables for OCRMyPDF Project ━━━━━━━━━━━━━━━━━━━━━━━━━

# Standard tags for resources
locals {
  specific_tags = {
  }  

  # Full resource prefix considering the environment
  resource_prefix = "${var.prefix}-${var.environment}"
  
  # Names of key resources
  lambda_uploader_name = "${var.prefix}-file-uploader-${var.environment}"
  lambda_status_name   = "${var.prefix}-status-updater-${var.environment}"
  ecs_cluster_name     = "${var.prefix}-ocr-cluster-${var.environment}"
  ecr_repository_name  = "${var.prefix}-ocrmypdf-${var.environment}"
  
  # S3 bucket names
  pdf_bucket_name      = "${var.prefix}-pdf-storage-${var.environment}"
  website_bucket_name  = "${var.prefix}-website-${var.environment}"
  
  # Messaging resource names
  sqs_queue_name       = "${var.prefix}-ocr-queue-${var.environment}"
  sqs_dlq_name         = "${var.prefix}-ocr-dlq-${var.environment}"
  sns_topic_name       = "${var.prefix}-ocr-notifications-${var.environment}"
  
  # API Gateway resource names
  api_name             = "${var.prefix}-ocr-api-${var.environment}"
  
  # VPC configuration
  create_vpc           = var.vpc_id == null
}
