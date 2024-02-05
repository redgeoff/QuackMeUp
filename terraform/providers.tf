terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15"
    }
  }

  backend "s3" {
    bucket = var.terraform_bucket_name
    key    = "terraform-state/quackmeup/terraform.tfstate"
    region = var.region
  }
}

provider "aws" {
  region = var.region
}