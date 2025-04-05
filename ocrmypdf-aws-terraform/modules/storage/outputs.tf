# ━━━ Storage Module Output Variables ━━━━━━━━━━━━━━━━━━━━━━━━━━━━

output "pdf_bucket_id" {
  description = "ID of the PDF storage bucket"
  value       = aws_s3_bucket.pdf_storage.id
}

output "pdf_bucket_arn" {
  description = "ARN of the PDF storage bucket"
  value       = aws_s3_bucket.pdf_storage.arn
}

output "website_bucket_id" {
  description = "ID of the website interface bucket"
  value       = aws_s3_bucket.website.id
}

output "website_bucket_arn" {
  description = "ARN of the website interface bucket"
  value       = aws_s3_bucket.website.arn
}

output "website_url" {
  description = "URL of the website interface"
  value       = "http://${aws_s3_bucket.website.bucket}.s3-website-${split("-", aws_s3_bucket.website.region)[0]}.amazonaws.com"
}

output "website_domain" {
  description = "Domain of S3 web hosting"
  value       = aws_s3_bucket_website_configuration.website.website_domain
}

output "website_endpoint" {
  description = "Endpoint of S3 web hosting"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}
