locals {
  aws_region          = var.region
  formatted_timestamp = formatdate("YYYYMMDDHHmmss", timestamp())
}
