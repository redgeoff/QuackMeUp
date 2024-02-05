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
      PROJECT_NAME     = var.project_name
      LOGS_BUCKET_NAME = var.logs_bucket_name
      REGION           = var.region
    }
  }

  depends_on = [null_resource.push_image]
}
