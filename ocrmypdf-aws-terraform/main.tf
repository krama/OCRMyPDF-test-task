# Main Terraform file for OCRMyPDF service
# Combines all modules into a single infrastructure

# Networking module
module "networking" {
  source = "./modules/networking"

  prefix      = var.prefix
  environment = var.environment
  region      = var.region
  vpc_id      = var.vpc_id
  tags        = local.resource_tags
}

# Storage module
module "storage" {
  source = "./modules/storage"

  prefix                = var.prefix
  environment           = var.environment
  s3_force_destroy      = var.s3_force_destroy
  tags                  = local.resource_tags
}

# Messaging module
module "messaging" {
  source = "./modules/messaging"

  prefix                 = var.prefix
  environment            = var.environment
  sqs_visibility_timeout = var.sqs_visibility_timeout
  sqs_message_retention  = var.sqs_message_retention
  tags                   = local.resource_tags
}

# API Gateway module
module "api" {
  source = "./modules/api"

  prefix               = var.prefix
  environment          = var.environment
  api_stage_name       = var.api_stage_name
  file_uploader_lambda = module.compute.file_uploader_lambda
  tags                 = local.resource_tags

  depends_on = [module.compute]
}

# Container module
module "container" {
  source = "./modules/container"

  prefix                = var.prefix
  environment           = var.environment
  docker_hub_image      = var.docker_hub_image
  use_localstack        = var.use_localstack
  localstack_endpoint   = var.localstack_endpoint
  localstack_access_key = var.localstack_access_key
  localstack_secret_key = var.localstack_secret_key
  force_delete_ecr      = var.force_delete_ecr
  region                = var.region
  tags                  = local.resource_tags
}

# Security module
module "security" {
  source = "./modules/security"

  prefix             = var.prefix
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  sqs_queue_arn      = module.messaging.sqs_queue_arn
  sns_topic_arn      = module.messaging.sns_topic_arn
  pdf_bucket_arn     = module.storage.pdf_bucket_arn
  website_bucket_arn = module.storage.website_bucket_arn
  tags               = local.resource_tags
}

# Compute module
module "compute" {
  source = "./modules/compute"

  prefix                       = var.prefix
  environment                  = var.environment
  region                       = var.region
  ecs_cpu                      = var.ecs_cpu
  ecs_memory                   = var.ecs_memory
  ecs_desired_count            = var.ecs_desired_count
  min_capacity                 = var.min_capacity
  max_capacity                 = var.max_capacity
  target_sqs_messages_per_task = var.target_sqs_messages_per_task
  docker_hub_image             = var.docker_hub_image
  lambda_timeout               = var.lambda_timeout
  lambda_memory_size           = var.lambda_memory_size
  private_subnet_ids           = module.networking.private_subnet_ids
  vpc_id                       = module.networking.vpc_id
  
  # Resources from other modules
  ecr_repository_url     = module.container.ecr_repository_url
  sqs_queue_url          = module.messaging.sqs_queue_url
  sqs_queue_name         = local.sqs_queue_name
  sns_topic_arn          = module.messaging.sns_topic_arn
  pdf_bucket_id          = module.storage.pdf_bucket_id
  website_bucket_id      = module.storage.website_bucket_id
  
  # IAM roles
  lambda_upload_role_arn    = module.security.lambda_upload_role_arn
  lambda_status_role_arn    = module.security.lambda_status_role_arn
  ecs_execution_role_arn    = module.security.ecs_execution_role_arn
  ecs_task_role_arn         = module.security.ecs_task_role_arn
  security_group_lambda     = module.security.security_group_lambda_id
  security_group_ecs        = module.security.security_group_ecs_id
  
  tags                   = local.resource_tags
  
  depends_on = [
    module.security,
    module.networking,
    module.messaging,
    module.storage,
    module.container
  ]
}

# Frontend module
module "frontend" {
  source = "./modules/frontend"

  prefix                = var.prefix
  environment           = var.environment
  website_bucket        = module.storage.website_bucket_id
  api_endpoint          = module.api.api_endpoint
  use_localstack        = var.use_localstack
  localstack_endpoint   = var.localstack_endpoint
  api_id                = module.api.api_id
  api_stage_name        = var.api_stage_name
  region                = var.region
  tags                  = local.resource_tags
  
  depends_on = [
    module.storage,
    module.api
  ]
}