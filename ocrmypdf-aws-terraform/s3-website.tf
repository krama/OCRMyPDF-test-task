#  ╔╗ ╦ ╦╔═╗╦╔═╔═╗╔╦╗  ╔═╗╔═╗╦═╗  ╔═╗╔╦╗╔═╗╔╦╗╦╔═╗
#  ╠╩╗║ ║║  ╠╩╗║╣  ║   ╠╣ ║ ║╠╦╝  ╚═╗ ║ ╠═╣ ║ ║║  
#  ╚═╝╚═╝╚═╝╩ ╩╚═╝ ╩   ╚  ╚═╝╩╚═  ╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝

resource "aws_s3_bucket" "website" {
  bucket = "${var.prefix}-website-${var.environment}"
  
  tags = {
    Name = "${var.prefix}-website"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

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

#  ╦ ╦╔═╗╦  ╔═╗╔═╗╔╦╗  ╔═╗╦═╗╔═╗╔╗╔╔═╗╔╗╔╔╦╗  ╔╦╗╔═╗  ╔╗ ╦ ╦╔═╗╦╔═╔═╗╔╦╗
#  ║ ║╠═╝║  ║ ║╠═╣ ║║  ╠╣ ╠╦╝║ ║║║║║╣ ║║║ ║║   ║ ║ ║  ╠╩╗║ ║║  ╠╩╗║╣  ║ 
#  ╚═╝╩  ╩═╝╚═╝╩ ╩═╩╝  ╚  ╩╚═╚═╝╝╚╝╚═╝╝╚╝═╩╝   ╩ ╚═╝  ╚═╝╚═╝╚═╝╩ ╩╚═╝ ╩ 
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"
  source = "${path.module}/frontend/index.html"
  content_type = "text/html"

  etag = filemd5("${path.module}/frontend/index.html")
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.website.id
  key          = "styles.css"
  source       = "${path.module}/frontend/style.css"
  content_type = "text/css"

  etag = filemd5("${path.module}/frontend/style.css")
}

resource "aws_s3_object" "app_js" {
  bucket = aws_s3_bucket.website.id
  key    = "app.js"
  source = "${path.module}/frontend/app.js"
  content_type = "application/javascript"

  etag = filemd5("${path.module}/frontend/app.js")
}