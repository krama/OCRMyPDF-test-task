#  ╔═╗╦═╗╔═╗╦  ╦╦╔╦╗╔═╗╦═╗╔═╗
#  ╠═╝╠╦╝║ ║╚╗╔╝║ ║║║╣ ╠╦╝╚═╗
#  ╩  ╩╚═╚═╝ ╚╝ ╩═╩╝╚═╝╩╚═╚═╝

provider "aws" {
  region = var.region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
endpoints {
  apigateway     = "http://localhost:4566"
  appautoscaling = "http://localhost:4566"
  cloudformation = "http://localhost:4566"
  cloudwatch     = "http://localhost:4566"
  cloudwatchlogs = "http://localhost:4566"
  dynamodb       = "http://localhost:4566"
  ec2            = "http://localhost:4566"
  ecr            = "http://localhost:4566"
  ecs            = "http://localhost:4566"
  es             = "http://localhost:4566"
  firehose       = "http://localhost:4566"
  iam            = "http://localhost:4566"
  kinesis        = "http://localhost:4566"
  kms            = "http://localhost:4566"
  lambda         = "http://localhost:4566"
  redshift       = "http://localhost:4566"
  route53        = "http://localhost:4566"
  s3             = "http://localhost:4566"
  secretsmanager = "http://localhost:4566"
  ses            = "http://localhost:4566"
  sns            = "http://localhost:4566"
  sqs            = "http://localhost:4566"
  ssm            = "http://localhost:4566"
  stepfunctions  = "http://localhost:4566"
  sts            = "http://localhost:4566"
}
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
#data "aws_ecr_authorization_token" "token" {}

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
}
#  ╔╦╗╔═╗╦═╗╦═╗╔═╗╔═╗╔═╗╦═╗╔╦╗  ╔═╗╔╦╗╔═╗╔╦╗╔═╗
#   ║ ║╣ ╠╦╝╠╦╝╠═╣╠╣ ║ ║╠╦╝║║║  ╚═╗ ║ ╠═╣ ║ ║╣ 
#   ╩ ╚═╝╩╚═╩╚═╩ ╩╚  ╚═╝╩╚═╩ ╩  ╚═╝ ╩ ╩ ╩ ╩ ╚═╝

#   backend "s3" {
#     bucket = "ocrmypdf-state-bucket"
#     key    = "ocrmypdf/terraform.tfstate"
#     region = var.region
#   }
# }
