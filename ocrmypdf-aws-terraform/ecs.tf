resource "aws_ecs_cluster" "ocr_cluster" {
  name = "${var.prefix}-ocr-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "ocrmypdf" {
  name              = "/ecs/${var.prefix}-ocrmypdf-${var.environment}"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "ocrmypdf" {
  family                   = "${var.prefix}-ocrmypdf-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "ocrmypdf"
      image     = length(var.docker_hub_image) > 0 ? var.docker_hub_image : "${aws_ecr_repository.ocrmypdf.repository_url}:latest"
      essential = true

      environment = [
        { name = "SQS_QUEUE_URL", value = aws_sqs_queue.ocr_queue.url },
        { name = "S3_BUCKET", value = aws_s3_bucket.pdf_storage.id },
        { name = "SNS_TOPIC_ARN", value = aws_sns_topic.ocr_notifications.arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ocrmypdf.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "${var.prefix}-ocrmypdf"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "ocrmypdf" {
  name            = "${var.prefix}-ocrmypdf-${var.environment}"
  cluster         = aws_ecs_cluster.ocr_cluster.id
  task_definition = aws_ecs_task_definition.ocrmypdf.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = length(var.subnet_ids) > 0 ? var.subnet_ids : [
      aws_subnet.private_subnet_1[0].id,
      aws_subnet.private_subnet_2[0].id
    ]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

resource "aws_appautoscaling_target" "ocrmypdf" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ocr_cluster.name}/${aws_ecs_service.ocrmypdf.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "sqs_scaling" {
  name               = "${var.prefix}-sqs-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ocrmypdf.resource_id
  scalable_dimension = aws_appautoscaling_target.ocrmypdf.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ocrmypdf.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 10
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "SQSQueueMessagesVisiblePerTask"
      resource_label         = "${aws_sqs_queue.ocr_queue.name}/${aws_ecs_service.ocrmypdf.name}"
    }
  }
}