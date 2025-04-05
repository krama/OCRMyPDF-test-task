# Variables for production environment (prod)

environment = "prod"
region      = "eu-central-2"
prefix      = "ocrmypdf"

# LocalStack settings
use_localstack = false

# ECS settings
ecs_desired_count = 3
min_capacity      = 3
max_capacity      = 10
ecs_cpu           = "2048"
ecs_memory        = "4096"

# S3 settings
s3_force_destroy  = false  # Protection against accidental deletion in production

# Lambda settings
lambda_timeout    = 90
lambda_memory_size = 1024

# SQS settings
sqs_visibility_timeout = 900
sqs_message_retention  = 259200

# Autoscaling settings
target_sqs_messages_per_task = 5
