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

resource "aws_iam_role" "lambda_role" {
  name = "log_exporter_function_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/../src/log_exporter"
  output_path = "${path.module}/../ignored/log-exporter.zip"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename    = "${path.module}/../ignored/log-exporter.zip"
  function_name = "log_exporter_function"
  role        = aws_iam_role.lambda_role.arn
  handler     = "lambda_handler.lambda_handler"
  runtime     = "python3.8"
  depends_on  = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}