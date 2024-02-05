resource "aws_s3_bucket" "quackmeup_bucket" {
  bucket = var.logs_bucket_name

  # Uncomment to destroy all objects in the bucket before destroying the bucket
  # force_destroy = true
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = ["${aws_s3_bucket.quackmeup_bucket.arn}"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.quackmeup_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "quackmeup_bucket_policy" {
  bucket = aws_s3_bucket.quackmeup_bucket.bucket
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}