# Module for storing PDF files and hosting the web interface for OCRMyPDF

# S3 bucket for storing PDF files
resource "aws_s3_bucket" "pdf_storage" {
  bucket        = "${var.prefix}-pdf-storage-${var.environment}"
  force_destroy = var.s3_force_destroy
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-pdf-storage"
    }
  )
}

# Lifecycle configuration for the PDF bucket
resource "aws_s3_bucket_lifecycle_configuration" "pdf_lifecycle" {
  bucket = aws_s3_bucket.pdf_storage.id

  rule {
    id     = "cleanup-processing"
    status = "Enabled"
    
    expiration {
      days = 7
    }
    
    filter {
      prefix = "processing/"
    }
  }
}

# S3 bucket for hosting the web interface
resource "aws_s3_bucket" "website" {
  bucket        = "${var.prefix}-website-${var.environment}"
  force_destroy = var.s3_force_destroy
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-website"
    }
  )
}

# Website configuration for the web interface bucket
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# CORS configuration for the web interface bucket
resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# Public access policy for the web interface bucket
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}
