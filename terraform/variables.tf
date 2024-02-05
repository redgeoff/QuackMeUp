variable "terraform_bucket_name" {
  type = string
}

variable "region" {
  description = "The region where AWS operations will take place"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type = string
}

variable "logs_bucket_name" {
  description = "The name of the S3 bucket for storing the logs exported to S3"
  type        = string
}
