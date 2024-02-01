variable "logs_bucket_name" {
  description = "The name of the S3 bucket for storing the logs exported to S3"
  type        = string
}

resource "aws_s3_bucket" "quackmeup_bucket" {
  bucket = var.logs_bucket_name
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

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging_policy"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.region}:*:log-group:/aws/lambda/*"
      }
    ]
  })
}

resource "aws_iam_policy" "log_exporter_policy" {
  name        = "log_exporter_policy"
  description = "Policy for the Log Exporter Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "logs:ListTagsLogGroup",
          "logs:CreateExportTask"
        ],
        Resource = "arn:aws:logs:${var.region}:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ],
        Resource = "arn:aws:ssm:*:*:*log-exporter*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name               = "log_exporter_function_role"
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

resource "aws_iam_role_policy_attachment" "lambda_logs_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "log_exporter_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.log_exporter_policy.arn
}

resource "aws_lambda_function" "log_exporter_function" {
  function_name = "log_exporter_function"

  # The Docker image URI. Use a timestamp to ensure the latest image is loaded
  image_uri = "${aws_ecr_repository.quackmeup_repository.repository_url}:${local.formatted_timestamp}"

  package_type = "Image"
  timeout      = 60

  role = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      project_name     = var.project_name
      logs_bucket_name = var.logs_bucket_name
      region           = var.region
    }
  }

  depends_on = [null_resource.push_image]
}

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "every-4-hours"
  description         = "Trigger Lambda every 4 hours"
  schedule_expression = "rate(4 hours)"
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "InvokeLambdaFunction"
  arn       = aws_lambda_function.log_exporter_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_exporter_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.log_exporter_function.function_name}"
  retention_in_days = 90
}