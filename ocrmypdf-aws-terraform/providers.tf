provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "OCRMyPDF"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "docker" {
  registry_auth {
    address  = aws_ecr_repository.ocrmypdf.repository_url
    username = "AWS"
    password = data.aws_ecr_authorization_token.token.password
  }
}

data "aws_ecr_authorization_token" "token" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "ocrmypdf-state-bucket"
    key    = "ocrmypdf/terraform.tfstate"
    region = "eu-central-2"  # Hardcoded to match var.region default
  }
}