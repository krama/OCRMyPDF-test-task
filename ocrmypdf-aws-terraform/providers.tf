# Configuration of providers

provider "aws" {
  region = var.region

  # LocalStack configuration
  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      apigateway     = var.localstack_endpoint
      appautoscaling = var.localstack_endpoint
      cloudformation = var.localstack_endpoint
      cloudwatch     = var.localstack_endpoint
      cloudwatchlogs = var.localstack_endpoint
      dynamodb       = var.localstack_endpoint
      ec2            = var.localstack_endpoint
      ecr            = var.localstack_endpoint
      ecs            = var.localstack_endpoint
      es             = var.localstack_endpoint
      firehose       = var.localstack_endpoint
      iam            = var.localstack_endpoint
      kinesis        = var.localstack_endpoint
      kms            = var.localstack_endpoint
      lambda         = var.localstack_endpoint
      redshift       = var.localstack_endpoint
      route53        = var.localstack_endpoint
      s3             = var.localstack_endpoint
      secretsmanager = var.localstack_endpoint
      ses            = var.localstack_endpoint
      sns            = var.localstack_endpoint
      sqs            = var.localstack_endpoint
      ssm            = var.localstack_endpoint
      stepfunctions  = var.localstack_endpoint
      sts            = var.localstack_endpoint
    }
  }

  access_key                  = var.use_localstack ? var.localstack_access_key : null
  secret_key                  = var.use_localstack ? var.localstack_secret_key : null
  skip_credentials_validation = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  s3_use_path_style           = var.use_localstack

  default_tags {
    tags = {
      Project     = "OCRMyPDF"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Docker provider for interacting with ECR
provider "docker" {
  registry_auth {
    address  = module.container.ecr_repository_url
    username = "AWS"
    password = var.use_localstack ? "test" : data.aws_ecr_authorization_token.token[0].password
  }
}

# Get ECR authorization token for Docker
data "aws_ecr_authorization_token" "token" {
  count = var.use_localstack ? 0 : 1
}
