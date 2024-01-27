provider "aws" {
  region = "us-east-1"
}

variable "LOGS_BUCKET_NAME" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "default-logs-bucket-name"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.LOGS_BUCKET_NAME
}
