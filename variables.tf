variable "bucket_name_web" {
  type = string
}



variable "bucket_name_log" {
  type = string
}


variable "log_prefix" {
  description = "Prefix for log files in the log bucket"
  type        = string
  default     = "myprefix"
}
