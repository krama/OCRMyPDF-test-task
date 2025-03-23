provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "eu-central-2"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    kms            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    ecr            = "http://localhost:4566"
  }

  default_tags {
    tags = {
      Project     = "OCRMyPDF-test-task"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "docker" {
  registry_auth {
    address = "${var.prefix}-ocrmypdf-${var.environment}.dkr.ecr.eu-central-2.localhost.localstack.cloud:4566"
    username = "AWS"
    password = "test"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}