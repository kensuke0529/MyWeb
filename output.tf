# outputs.tf
output "website_url" {
  description = "S3 Website endpoint URL"
  value       = "http://${var.bucket_name_web}.s3-website-us-east-1.amazonaws.com"
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.myweb.domain_name
}

output "logs_bucket" {
  description = "CloudFront logs S3 bucket name"
  value       = aws_s3_bucket.mylogs.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.myweb.id
}

output "website_bucket" {
  description = "S3 website bucket name"
  value       = aws_s3_bucket.myweb.bucket
}
