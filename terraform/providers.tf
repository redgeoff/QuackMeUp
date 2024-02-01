terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15"
    }
  }

  backend "s3" {
    bucket = "quackmeup-terraform-bucket"
    key    = "terraform-state/quackmeup/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}