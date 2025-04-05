# Development environment variables

environment = "dev"
region      = "eu-central-2"
prefix      = "ocrmypdf"

# LocalStack settings
use_localstack    = true
localstack_endpoint = "http://localhost:4566"

# ECS settings
ecs_desired_count = 1
min_capacity      = 1
max_capacity      = 3
ecs_cpu           = "512"
ecs_memory        = "1024"

# S3 settings
s3_force_destroy  = true

# Lambda settings
lambda_timeout    = 30
lambda_memory_size = 256

# SQS settings
sqs_visibility_timeout = 300
sqs_message_retention  = 86400
