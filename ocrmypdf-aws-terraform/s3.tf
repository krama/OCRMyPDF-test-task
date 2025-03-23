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
}

# Input dir (real file)
resource "aws_s3_object" "input_readme" {
  bucket       = aws_s3_bucket.pdf_storage.id
  key          = "input/readme.txt"
  source       = "${path.module}/s3-seed/input/readme.txt"
  content_type = "text/plain"
}

# Output dir (real file)
resource "aws_s3_object" "output_readme" {
  bucket       = aws_s3_bucket.pdf_storage.id
  key          = "output/readme.txt"
  source       = "${path.module}/s3-seed/output/readme.txt"
  content_type = "text/plain"
}

# Processing dir (real file)
resource "aws_s3_object" "processing_readme" {
  bucket       = aws_s3_bucket.pdf_storage.id
  key          = "processing/readme.txt"
  source       = "${path.module}/s3-seed/processing/readme.txt"
  content_type = "text/plain"
}
