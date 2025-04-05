# Frontend module output variables

output "frontend_files" {
  description = "List of files uploaded to the website bucket"
  value = [
    aws_s3_object.index_html.key,
    aws_s3_object.styles_css.key,
    aws_s3_object.app_js.key,
    aws_s3_object.status_json.key
  ]
}

output "app_js_etag" {
  description = "ETag of the JavaScript file"
  value       = aws_s3_object.app_js.etag
}

output "index_html_etag" {
  description = "ETag of the HTML file"
  value       = aws_s3_object.index_html.etag
}

output "styles_css_etag" {
  description = "ETag of the CSS file"
  value       = aws_s3_object.styles_css.etag
}
