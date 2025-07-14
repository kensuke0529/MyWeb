variable "bucket_name_web" {
  description = "The name of the S3 bucket to host the website"
  type        = string
}

variable "bucket_name_log" {
  description = "The name of the S3 bucket to store CloudFront logs"
  type        = string
}

variable "log_prefix" {
  description = "Prefix for log files in the log bucket"
  type        = string
  default     = "myprefix"
}
