# Variables for staging environment

environment = "staging"
region      = "eu-central-2"
prefix      = "ocrmypdf"

# LocalStack settings
use_localstack = false

# ECS settings
ecs_desired_count = 2
min_capacity      = 2
max_capacity      = 5
ecs_cpu           = "1024"
ecs_memory        = "2048"

# S3 settings
s3_force_destroy  = true

# Lambda settings
lambda_timeout    = 60
lambda_memory_size = 512

# SQS settings
sqs_visibility_timeout = 600
sqs_message_retention  = 172800
