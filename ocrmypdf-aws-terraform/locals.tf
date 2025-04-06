# ━━━ Local Variables for OCRMyPDF Project ━━━━━━━━━━━━━━━━━━━━━━━━━

locals {
  # Common tags for all resources
  common_tags = {
    Project     = "OCRMyPDF"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }

  # Merge common tags with any specific tags provided
  resource_tags = merge(local.common_tags, var.tags)

  # Full resource prefix considering the environment
  resource_prefix = "${var.prefix}-${var.environment}"
  
  # Names of key resources
  lambda_uploader_name = "${local.resource_prefix}-file-uploader"
  lambda_status_name   = "${local.resource_prefix}-status-updater"
  ecs_cluster_name     = "${local.resource_prefix}-ocr-cluster"
  ecr_repository_name  = "${local.resource_prefix}-ocrmypdf"
  
  # S3 bucket names
  pdf_bucket_name      = "${local.resource_prefix}-pdf-storage"
  website_bucket_name  = "${local.resource_prefix}-website"
  
  # Messaging resource names
  sqs_queue_name       = "${local.resource_prefix}-ocr-queue"
  sqs_dlq_name         = "${local.resource_prefix}-ocr-dlq"
  sns_topic_name       = "${local.resource_prefix}-ocr-notifications"
  
  # API Gateway resource names
  api_name             = "${local.resource_prefix}-ocr-api"
  
  # VPC configuration
  create_vpc           = var.vpc_id == null
}