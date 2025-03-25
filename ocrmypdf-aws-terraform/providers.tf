#  ╔═╗╦═╗╔═╗╦  ╦╦╔╦╗╔═╗╦═╗╔═╗
#  ╠═╝╠╦╝║ ║╚╗╔╝║ ║║║╣ ╠╦╝╚═╗
#  ╩  ╩╚═╚═╝ ╚╝ ╩═╩╝╚═╝╩╚═╚═╝

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "OCRMyPDF"  # Project tag
      Environment = var.environment  # Environment tag
      ManagedBy   = "Terraform"
    }
  }
}

# Docker provider configuration for building/pushing images to ECR
provider "docker" {
  registry_auth {
    address  = aws_ecr_repository.ocrmypdf.repository_url
    username = "AWS"
    password = data.aws_ecr_authorization_token.token.password
  }
}

# Data source for AWS ECR authorization token
data "aws_ecr_authorization_token" "token" {}

# Terraform settings and backend configuration for remote state storage
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

#  ╔╦╗╔═╗╦═╗╦═╗╔═╗╔═╗╔═╗╦═╗╔╦╗  ╔═╗╔╦╗╔═╗╔╦╗╔═╗
#   ║ ║╣ ╠╦╝╠╦╝╠═╣╠╣ ║ ║╠╦╝║║║  ╚═╗ ║ ╠═╣ ║ ║╣ 
#   ╩ ╚═╝╩╚═╩╚═╩ ╩╚  ╚═╝╩╚═╩ ╩  ╚═╝ ╩ ╩ ╩ ╩ ╚═╝

  backend "s3" {
    bucket = "ocrmypdf-state-bucket"
    key    = "ocrmypdf/terraform.tfstate"
    region = var.region
  }
}
