#  ╔╗ ╦ ╦╔═╗╦╔═╔═╗╔╦╗  ╔═╗╔═╗╦═╗  ╔═╗╔╦╗╔═╗╔╦╗╦╔═╗
#  ╠╩╗║ ║║  ╠╩╗║╣  ║   ╠╣ ║ ║╠╦╝  ╚═╗ ║ ╠═╣ ║ ║║  
#  ╚═╝╚═╝╚═╝╩ ╩╚═╝ ╩   ╚  ╚═╝╩╚═  ╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝

resource "aws_s3_bucket" "pdf_storage" {
  bucket = "${var.prefix}-pdf-storage-${var.environment}"
  
  tags = {
    Name = "${var.prefix}-pdf-storage"
  }
}

# Set up lifecycle rule to expire files in 'processing' directory after 7 days
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
