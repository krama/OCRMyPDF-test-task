# ┏┓ ╻ ╻┏━╸╻┏ ┏━╸╺┳╸   ┏━╸┏━┓┏━┓   ╻ ╻┏━╸┏┓ ┏━┓╻╺┳╸┏━╸
# ┣┻┓┃ ┃┃  ┣┻┓┣╸  ┃    ┣╸ ┃ ┃┣┳┛   ┃╻┃┣╸ ┣┻┓┗━┓┃ ┃ ┣╸ 
# ┗━┛┗━┛┗━╸╹ ╹┗━╸ ╹    ╹  ┗━┛╹┗╸   ┗┻┛┗━╸┗━┛┗━┛╹ ╹ ┗━╸

resource "aws_s3_bucket" "website" {
  bucket = "${var.prefix}-website-${var.environment}"
  force_destroy = var.s3_force_destroy
  
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

# ╻ ╻┏━┓╻  ┏━┓┏━┓╺┳┓   ╻ ╻┏━╸┏┓ ┏━┓╻╺┳╸┏━╸   ╺┳╸┏━┓   ┏━┓┏━┓
# ┃ ┃┣━┛┃  ┃ ┃┣━┫ ┃┃   ┃╻┃┣╸ ┣┻┓┗━┓┃ ┃ ┣╸     ┃ ┃ ┃   ┗━┓╺━┫
# ┗━┛╹  ┗━╸┗━┛╹ ╹╺┻┛   ┗┻┛┗━╸┗━┛┗━┛╹ ╹ ┗━╸    ╹ ┗━┛   ┗━┛┗━┛
# Creating template for app.js
data "template_file" "app_js" {
  template = file("${path.module}/frontend/app.js.tpl")
  vars = {
    api_endpoint = var.use_localstack ? "${var.localstack_endpoint}/restapis/${aws_api_gateway_rest_api.ocr_api.id}/${var.api_stage_name}/_user_request_/upload" : "${aws_api_gateway_deployment.api_deployment.invoke_url}/upload"
  }
}

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

# Using template for app.js
resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.website.id
  key          = "app.js"
  content      = data.template_file.app_js.rendered
  content_type = "application/javascript"
  etag         = md5(data.template_file.app_js.rendered)
}

# Creating empty status file
resource "aws_s3_object" "status_json" {
  bucket       = aws_s3_bucket.website.id
  key          = "status/status.json"
  content      = jsonencode({ "files": {} })
  content_type = "application/json"
}