#  ╔═╗╔═╗╔═╗  ╔═╗╦  ╦ ╦╔═╗╔╦╗╔═╗╦═╗
#  ║╣ ║  ╚═╗  ║  ║  ║ ║╚═╗ ║ ║╣ ╠╦╝
#  ╚═╝╚═╝╚═╝  ╚═╝╩═╝╚═╝╚═╝ ╩ ╚═╝╩╚═

resource "aws_ecs_cluster" "ocr_cluster" {
  name = "${var.prefix}-ocr-cluster-${var.environment}"  # Cluster name
  setting {
    name  = "containerInsights"  # Enable container insights
    value = "enabled"
  }
}

#  ╔═╗╦  ╔═╗╦ ╦╔╦╗╦ ╦╔═╗╔╦╗╔═╗╦ ╦  ╔═╗╔═╗╔═╗
#  ║  ║  ║ ║║ ║ ║║║║║╠═╣ ║ ║  ╠═╣  ║╣ ║  ╚═╗
#  ╚═╝╩═╝╚═╝╚═╝═╩╝╚╩╝╩ ╩ ╩ ╚═╝╩ ╩  ╚═╝╚═╝╚═╝

resource "aws_cloudwatch_log_group" "ocrmypdf" {
  name              = "/ecs/${var.prefix}-ocrmypdf-${var.environment}"  # Log group name
  retention_in_days = 30  # Log retention period
}

#  ╔═╗╔═╗╔═╗  ╔╦╗╔═╗╔═╗╦╔═  ╔═╗╔═╗╦═╗  ╔═╗╔═╗╦═╗╔╦╗╦ ╦╔═╗╔╦╗╔═╗
#  ║╣ ║  ╚═╗   ║ ╠═╣╚═╗╠╩╗  ╠╣ ║ ║╠╦╝  ║ ║║  ╠╦╝║║║╚╦╝╠═╝ ║║╠╣ 
#  ╚═╝╚═╝╚═╝   ╩ ╩ ╩╚═╝╩ ╩  ╚  ╚═╝╩╚═  ╚═╝╚═╝╩╚═╩ ╩ ╩ ╩  ═╩╝╚  

resource "aws_ecs_task_definition" "ocrmypdf" {
  family                   = "${var.prefix}-ocrmypdf-${var.environment}"  # Task family name
  requires_compatibilities = ["FARGATE"]  # Use Fargate launch type
  network_mode             = "awsvpc"  # Networking mode
  cpu                      = "1024"  # CPU units
  memory                   = "2048"  # Memory in MB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn  # Execution role ARN
  task_role_arn            = aws_iam_role.ecs_task_role.arn  # Task role ARN

  # Container definition with environment variables and logging
  container_definitions = jsonencode([
    {
      name      = "ocrmypdf"  # Container name
      image     = length(var.docker_hub_image) > 0 ? var.docker_hub_image : "${aws_ecr_repository.ocrmypdf.repository_url}:latest"
      essential = true  # Essential container flag
      environment = [
        { name = "SQS_QUEUE_URL", value = aws_sqs_queue.ocr_queue.url },
        { name = "S3_BUCKET", value = aws_s3_bucket.pdf_storage.id },
        { name = "SNS_TOPIC_ARN", value = aws_sns_topic.ocr_notifications.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ocrmypdf.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "${var.prefix}-ocrmypdf"
        }
      }
    }
  ])
}

#  ╔═╗╔═╗╔═╗  ╔═╗╔═╗╦═╗╦  ╦╦╔═╗╔═╗
#  ║╣ ║  ╚═╗  ╚═╗║╣ ╠╦╝╚╗╔╝║║  ║╣ 
#  ╚═╝╚═╝╚═╝  ╚═╝╚═╝╩╚═ ╚╝ ╩╚═╝╚═╝

resource "aws_ecs_service" "ocrmypdf" {
  name            = "${var.prefix}-ocrmypdf-${var.environment}"  # Service name
  cluster         = aws_ecs_cluster.ocr_cluster.id  # Cluster ID
  task_definition = aws_ecs_task_definition.ocrmypdf.arn  # Task definition ARN
  desired_count   = 1  # Desired task count
  launch_type     = "FARGATE"  # Launch type

  network_configuration {
    subnets = length(var.subnet_ids) > 0 ? var.subnet_ids : [
      aws_subnet.private_subnet_1[0].id,
      aws_subnet.private_subnet_2[0].id
    ]
    security_groups  = [aws_security_group.ecs_sg.id]  # Security group for ECS
    assign_public_ip = true  # Assign public IP
  }
}

#  ╔═╗╦ ╦╔╦╗╔═╗   ╔═╗╔═╗╔═╗╦  ╦╔╗╔╔═╗  ╔╦╗╔═╗╦═╗╔═╗╔═╗╔╦╗  ╔═╗╔═╗╦═╗  ╔═╗╔═╗╔═╗
#  ╠═╣║ ║ ║ ║ ║───╚═╗║  ╠═╣║  ║║║║║ ╦   ║ ╠═╣╠╦╝║ ╦║╣  ║   ╠╣ ║ ║╠╦╝  ║╣ ║  ╚═╗
#  ╩ ╩╚═╝ ╩ ╚═╝   ╚═╝╚═╝╩ ╩╩═╝╩╝╚╝╚═╝   ╩ ╩ ╩╩╚═╚═╝╚═╝ ╩   ╚  ╚═╝╩╚═  ╚═╝╚═╝╚═╝

resource "aws_appautoscaling_target" "ocrmypdf" {
  max_capacity       = 10  # Maximum number of tasks
  min_capacity       = 1  # Minimum number of tasks
  resource_id        = "service/${aws_ecs_cluster.ocr_cluster.name}/${aws_ecs_service.ocrmypdf.name}"  # Resource ID
  scalable_dimension = "ecs:service:DesiredCount"  # Scalable dimension
  service_namespace  = "ecs"  # Service namespace
}

# Auto-scaling policy based on SQS messages per task
resource "aws_appautoscaling_policy" "sqs_scaling" {
  name               = "${var.prefix}-sqs-scaling-${var.environment}"  # Policy name
  policy_type        = "TargetTrackingScaling"  # Policy type
  resource_id        = aws_appautoscaling_target.ocrmypdf.resource_id  # Resource ID
  scalable_dimension = aws_appautoscaling_target.ocrmypdf.scalable_dimension  # Scalable dimension
  service_namespace  = aws_appautoscaling_target.ocrmypdf.service_namespace  # Service namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 10  # Target value (SQS messages per task)
    scale_in_cooldown  = 300  # Scale-in cooldown in seconds
    scale_out_cooldown = 60   # Scale-out cooldown in seconds
    predefined_metric_specification {
      predefined_metric_type = "SQSQueueMessagesVisiblePerTask"  # Predefined metric
      resource_label         = "${aws_sqs_queue.ocr_queue.name}/${aws_ecs_service.ocrmypdf.name}"  # Resource label
    }
  }
}
