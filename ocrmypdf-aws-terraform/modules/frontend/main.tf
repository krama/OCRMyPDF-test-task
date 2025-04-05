# Frontend module for OCRMyPDF

# Template for app.js file with API Endpoint insertion
data "template_file" "app_js" {
  template = file("${path.module}/files/app.js.tpl")
  vars = {
    api_endpoint = var.use_localstack ? "${var.localstack_endpoint}/restapis/${var.api_id}/${var.api_stage_name}/_user_request_/upload" : var.api_endpoint
  }
}

# Upload HTML page to bucket
resource "aws_s3_object" "index_html" {
  bucket       = var.website_bucket
  key          = "index.html"
  source       = "${path.module}/files/index.html"
  content_type = "text/html"

  etag = filemd5("${path.module}/files/index.html")
}

# Upload CSS styles to bucket
resource "aws_s3_object" "styles_css" {
  bucket       = var.website_bucket
  key          = "style.css"
  source       = "${path.module}/files/style.css"
  content_type = "text/css"

  etag = filemd5("${path.module}/files/style.css")
}

# Upload JS script to bucket using template
resource "aws_s3_object" "app_js" {
  bucket       = var.website_bucket
  key          = "app.js"
  content      = data.template_file.app_js.rendered
  content_type = "application/javascript"
  etag         = md5(data.template_file.app_js.rendered)
}

# Create empty status file
resource "aws_s3_object" "status_json" {
  bucket       = var.website_bucket
  key          = "status/status.json"
  content      = jsonencode({ "files": {} })
  content_type = "application/json"
}
