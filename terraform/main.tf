provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15"
    }
  }
}

variable "LOGS_BUCKET_NAME" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "default-logs-bucket-name"
}

resource "aws_s3_bucket" "quackmeup_bucket" {
  bucket = var.LOGS_BUCKET_NAME
}

resource "aws_ecr_repository" "quackmeup_repository" {
  name = "quackmeup"
}

resource "aws_ecr_lifecycle_policy" "quackmeup_lifecycle_policy" {
  repository = aws_ecr_repository.quackmeup_repository.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire images older than 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

data "aws_caller_identity" "current" {}

resource "null_resource" "docker_image" {
  triggers = {
    dockerfile_hash = filemd5("../Dockerfile")
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.quackmeup_repository.repository_url}:latest .."
  }
}

resource "docker_image" "quackmeup_image" {
  name = "${aws_ecr_repository.quackmeup_repository.repository_url}:latest"
  build {
    context = pathexpand("..")
  }
  depends_on = [null_resource.docker_image]
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

# resource "aws_iam_role_policy" "ecr_policy" {
#   name   = "ecr_policy"
#   role   = aws_iam_role.lambda_role.id
#   policy = data.aws_iam_policy_document.ecr_policy.json
# }

# resource "aws_iam_role" "lambda_role" {
#   name = "log_exporter_function_role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role" "lambda_role" {
#   name = "log_exporter_function_role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_policy" "iam_policy_for_lambda" {
#   name        = "aws_iam_policy_for_terraform_aws_lambda_role"
#   path        = "/"
#   description = "AWS IAM Policy for managing aws lambda role"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents"
#       ],
#       "Resource": "arn:aws:logs:*:*:*",
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
#   role       = aws_iam_role.lambda_role.name
#   policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
# }

# resource "null_resource" "build_and_package_lambda" {
#   provisioner "local-exec" {
#     command = <<EOF
#       cd ..
#       docker build -t lambda-builder .
#       docker run --name lambda-builder-container lambda-builder
#       docker cp lambda-builder-container:/var/task ./ignored/lambda_package
#       docker rm lambda-builder-container
#       cd ./ignored/lambda_package && zip -r ../lambda_package.zip .
#     EOF
#   }
#   triggers = {
#     build_trigger = "${timestamp()}"
#   }
# }

# resource "aws_lambda_function" "terraform_lambda_func" {
#   filename    = "lambda_package.zip"
#   function_name = "log_exporter_function"
#   role        = aws_iam_role.lambda_role.arn
#   handler     = "lambda_handler.lambda_handler"
#   runtime     = "python3.11"
#   depends_on  = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role, resource.null_resource.build_and_package_lambda]
# }