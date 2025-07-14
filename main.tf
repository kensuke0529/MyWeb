terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  s3_origin_id = "myS3Origin"
  log_prefix   = "myprefix"
}

# WEBSITE BUCKET: Static site content bucket
resource "aws_s3_bucket" "myweb" {
  bucket = var.bucket_name_web
}

resource "aws_s3_bucket_website_configuration" "myweb" {
  bucket = aws_s3_bucket.myweb.id

  index_document {
    suffix = "index.html"
  }
}

# Allow public access on website bucket
resource "aws_s3_bucket_public_access_block" "public_access_web" {
  bucket = aws_s3_bucket.myweb.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read access to website bucket
data "aws_iam_policy_document" "public_read" {
  statement {
    sid    = "AllowListBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.myweb.arn]
  }

  statement {
    sid    = "AllowGetObject"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.myweb.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.myweb.id
  policy = data.aws_iam_policy_document.public_read.json
}

# LOGGING BUCKET: For CloudFront logs
resource "aws_s3_bucket" "mylogs" {
  bucket = var.bucket_name_log
  acl    = "log-delivery-write"
}

# Enable ACLs on logging bucket by setting object ownership to allow ACLs (not "BucketOwnerEnforced")
resource "aws_s3_bucket_ownership_controls" "mylogs" {
  bucket = aws_s3_bucket.mylogs.id

  rule {
    # Allows ACLs; required for CloudFront logging
    object_ownership = "BucketOwnerPreferred"  
  }
}

# Public access block for logs bucket 
resource "aws_s3_bucket_public_access_block" "public_access_logs" {
  bucket = aws_s3_bucket.mylogs.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_caller_identity" "current" {}

# Bucket policy allowing CloudFront to put logs into the logging bucket
resource "aws_s3_bucket_policy" "logging_bucket_policy" {
  bucket = aws_s3_bucket.mylogs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontLogs"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.mylogs.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudfront::*:distribution/*"
          }
        }
      }
    ]
  })
}

# CLOUD FRONT DISTRIBUTION pointing to the website bucket origin
resource "aws_cloudfront_distribution" "myweb" {
  origin {
    domain_name = "${var.bucket_name_web}.s3-website-us-east-1.amazonaws.com"
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }


  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.mylogs.bucket_regional_domain_name
    prefix          = local.log_prefix
  }
}
