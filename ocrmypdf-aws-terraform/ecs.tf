resource "aws_ecs_cluster" "ocr_cluster" {
  name = "${var.prefix}-ocr-cluster-${var.environment}" // ECS cluster name
  setting {
    name  = "containerInsights" // Enable container insights
    value = "enabled"           // Enable container insights
  }
}

resource "aws_cloudwatch_log_group" "ocrmypdf" {
  name              = "/ecs/${var.prefix}-ocrmypdf-${var.environment}" // Log group name
  retention_in_days = 30 // Log retention in days
}

resource "aws_ecs_task_definition" "ocrmypdf" {
  family                   = "${var.prefix}-ocrmypdf-${var.environment}" // Task definition name
  requires_compatibilities = ["FARGATE"] // Use FARGATE launch type
  network_mode             = "awsvpc" // Use awsvpc network mode
  cpu                      = "1024" // Use 1024 CPU
  memory                   = "2048" // Use 2048 memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn // Use execution role
  task_role_arn            = aws_iam_role.ecs_task_role.arn // Use task role

  container_definitions = jsonencode([
    {
      name      = "ocrmypdf" // Container name
      image     = var.use_docker_hub ? var.docker_hub_image : "${aws_ecr_repository.ocrmypdf.repository_url}:latest" // Container image
      essential = true // Container is essential
      environment = [
        { name = "SQS_QUEUE_URL", value = aws_sqs_queue.ocr_queue.url }, // SQS queue URL
        { name = "S3_BUCKET", value = aws_s3_bucket.pdf_storage.id }, // S3 bucket
        { name = "SNS_TOPIC_ARN", value = aws_sns_topic.ocr_notifications.arn } // SNS topic ARN
      ]
      logConfiguration = {
        logDriver = "awslogs" // Log driver
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ocrmypdf.name, // Log group
          awslogs-region        = var.region, // Region
          awslogs-stream-prefix = "${var.prefix}-ocrmypdf" // Log stream prefix
        }
      }
    }
  ])
  
  depends_on = [
    aws_iam_role.ecs_execution_role,
    aws_iam_role.ecs_task_role,
    aws_ecr_repository.ocrmypdf,
    aws_cloudwatch_log_group.ocrmypdf,
    aws_sqs_queue.ocr_queue,
    aws_s3_bucket.pdf_storage,
    aws_sns_topic.ocr_notifications,
    null_resource.docker_pull_and_push
  ]
}

resource "aws_ecs_service" "ocrmypdf" {
  name            = "${var.prefix}-ocrmypdf-${var.environment}" // Service name
  cluster         = aws_ecs_cluster.ocr_cluster.id // Use ECS cluster
  task_definition = aws_ecs_task_definition.ocrmypdf.arn // Use task definition
  desired_count   = 1 // Desired number of tasks
  launch_type     = "FARGATE" // Use FARGATE launch type

  network_configuration {
    subnets = length(var.subnet_ids) > 0 ? var.subnet_ids : [
      local.create_vpc ? aws_subnet.subnets["private_1"].id : "",
      local.create_vpc ? aws_subnet.subnets["private_2"].id : ""
    ] // Use subnets
    security_groups  = [aws_security_group.ecs_sg.id] // Use security group
    assign_public_ip = true // Assign public IP
  }
  
  depends_on = [
    aws_ecs_cluster.ocr_cluster,
    aws_ecs_task_definition.ocrmypdf,
    aws_subnet.subnets,
    aws_security_group.ecs_sg
  ]
}

resource "aws_appautoscaling_target" "ocrmypdf" {
  max_capacity       = 10 // Maximum capacity
  min_capacity       = 1 // Minimum capacity
  resource_id        = "service/${aws_ecs_cluster.ocr_cluster.name}/${aws_ecs_service.ocrmypdf.name}" // Resource ID
  scalable_dimension = "ecs:service:DesiredCount" // Scalable dimension
  service_namespace  = "ecs" // Service namespace
  
  depends_on = [aws_ecs_cluster.ocr_cluster, aws_ecs_service.ocrmypdf]
}

resource "aws_appautoscaling_policy" "sqs_scaling" {
  name               = "${var.prefix}-sqs-scaling-${var.environment}" // Policy name
  policy_type        = "TargetTrackingScaling" // Policy type
  resource_id        = aws_appautoscaling_target.ocrmypdf.resource_id // Resource ID
  scalable_dimension = aws_appautoscaling_target.ocrmypdf.scalable_dimension // Scalable dimension
  service_namespace  = aws_appautoscaling_target.ocrmypdf.service_namespace // Service namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 10 // Target value
    scale_in_cooldown  = 300 // Scale in cooldown
    scale_out_cooldown = 60 // Scale out cooldown
    predefined_metric_specification {
      predefined_metric_type = "SQSQueueMessagesVisiblePerTask" // Predefined metric
      resource_label         = "${aws_sqs_queue.ocr_queue.name}/${aws_ecs_service.ocrmypdf.name}" // Resource label
    }
  }
  
  depends_on = [aws_appautoscaling_target.ocrmypdf, aws_sqs_queue.ocr_queue, aws_ecs_service.ocrmypdf]
}

