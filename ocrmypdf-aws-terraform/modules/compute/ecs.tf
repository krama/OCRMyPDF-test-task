# ECS components for OCRMyPDF

# ECS cluster
resource "aws_ecs_cluster" "ocr_cluster" {
  name = "${var.prefix}-ocr-cluster-${var.environment}"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-ocr-cluster"
    }
  )
}

# CloudWatch log group for ECS
resource "aws_cloudwatch_log_group" "ocrmypdf" {
  name              = "/ecs/${var.prefix}-ocrmypdf-${var.environment}"
  retention_in_days = 30
  
}

# ECS task definition
resource "aws_ecs_task_definition" "ocrmypdf" {
  family                   = "${var.prefix}-ocrmypdf-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "ocrmypdf"
      image     = var.docker_hub_image
      essential = true
      environment = [
        { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
        { name = "S3_BUCKET", value = var.pdf_bucket_id },
        { name = "SNS_TOPIC_ARN", value = var.sns_topic_arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ocrmypdf.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "${var.prefix}-ocrmypdf"
        }
      }
      portMappings = []
    }
  ])
  
}

# ECS service
resource "aws_ecs_service" "ocrmypdf" {
  name            = "${var.prefix}-ocrmypdf-${var.environment}"
  cluster         = aws_ecs_cluster.ocr_cluster.id
  task_definition = aws_ecs_task_definition.ocrmypdf.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_ecs]
    assign_public_ip = true
  }
  
}

# Target autoscaling group for ECS
resource "aws_appautoscaling_target" "ocrmypdf" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.ocr_cluster.name}/${aws_ecs_service.ocrmypdf.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Autoscaling policy for SQS
resource "aws_appautoscaling_policy" "sqs_scaling" {
  name               = "${var.prefix}-sqs-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ocrmypdf.resource_id
  scalable_dimension = aws_appautoscaling_target.ocrmypdf.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ocrmypdf.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.target_sqs_messages_per_task
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
    predefined_metric_specification {
      predefined_metric_type = "SQSQueueMessagesVisiblePerTask"
      resource_label         = "${var.sqs_queue_name}/${aws_ecs_service.ocrmypdf.name}"
    }
  }
}
