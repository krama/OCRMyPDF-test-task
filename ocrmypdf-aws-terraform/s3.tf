resource "aws_s3_bucket" "pdf_storage" {
  bucket = "${var.prefix}-pdf-storage-${var.environment}"
  
  tags = {
    Name = "${var.prefix}-pdf-storage"
  }
}

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
  
  depends_on = [aws_s3_bucket.pdf_storage]
}