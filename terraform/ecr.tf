resource "aws_ecr_repository" "quackmeup_repository" {
  name = "quackmeup"

  # Uncomment to destroy the repository even if it has images in it
  # force_destroy = true
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

resource "docker_image" "quackmeup_image" {
  name = "${aws_ecr_repository.quackmeup_repository.repository_url}:${local.formatted_timestamp}"
  build {
    context    = pathexpand("..")
    dockerfile = "../Dockerfile"
  }
}

resource "null_resource" "push_image" {
  provisioner "local-exec" {
    command = <<EOF
    docker build -t ${aws_ecr_repository.quackmeup_repository.repository_url}:${local.formatted_timestamp} ..
    echo $(aws ecr get-login-password --region ${local.aws_region}) | docker login --username AWS --password-stdin ${aws_ecr_repository.quackmeup_repository.repository_url}
    docker push ${aws_ecr_repository.quackmeup_repository.repository_url}:${local.formatted_timestamp}
    EOF
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}