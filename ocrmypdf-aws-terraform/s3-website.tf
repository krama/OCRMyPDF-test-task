# Create S3 bucket for website
resource "aws_s3_bucket" "website" {
  bucket = "${var.prefix}-website-${var.environment}"
  
  # Set Name tag
  tags = {
    Name = "${var.prefix}-website"
  }
}

# Configure S3 bucket for website
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  # Set index document
  index_document {
    suffix = "index.html"
  }

  # Set error document
  error_document {
    key = "error.html"
  }
  
  # Depends on bucket
  depends_on = [aws_s3_bucket.website]
}

# Enable CORS for website
resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  # Allow all origins
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
  
  # Depends on bucket
  depends_on = [aws_s3_bucket.website]
}

# Make website publicly accessible
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  # Allow public read access
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
  
  # Depends on bucket
  depends_on = [aws_s3_bucket.website]
}

# Upload website files
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"
  # Upload index.html
  source = "${path.module}/frontend/index.html"
  content_type = "text/html"

  # Calculate ETag
  etag = filemd5("${path.module}/frontend/index.html")
  
  # Depends on bucket
  depends_on = [aws_s3_bucket.website]
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.website.id
  key          = "styles.css"
  # Upload styles.css
  source       = "${path.module}/frontend/style.css"
  content_type = "text/css"

  # Calculate ETag
  etag = filemd5("${path.module}/frontend/style.css")
  
  # Depends on bucket
  depends_on = [aws_s3_bucket.website]
}

resource "aws_s3_object" "app_js" {
  bucket = aws_s3_bucket.website.id
  key    = "app.js"
  content_type = "application/javascript"
  
  # Replace API endpoint placeholder
  content = replace(
    file("${path.module}/frontend/app.js"),
    "const apiEndpoint = 'CHANGE_ME';",
    "const apiEndpoint = '${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.api_stage.stage_name}/upload';"
  )
  
  # Depends on bucket and API
  depends_on = [
    aws_s3_bucket.website,
    aws_api_gateway_deployment.api_deployment,
    aws_api_gateway_stage.api_stage
  ]
}

