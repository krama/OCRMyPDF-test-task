resource "aws_iam_role" "lambda_upload_role" {
  name = "${var.prefix}-lambda-upload-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_upload_policy" {
  name        = "${var.prefix}-lambda-upload-policy-${var.environment}"
  description = "Policy for upload Lambda"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = ["s3:PutObject", "s3:GetObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.pdf_storage.arn}/*"
      },
      {
        Action   = ["sqs:SendMessage"],
        Effect   = "Allow",
        Resource = aws_sqs_queue.ocr_queue.arn
      },
      {
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
  
  depends_on = [aws_s3_bucket.pdf_storage, aws_sqs_queue.ocr_queue]
}

resource "aws_iam_role_policy_attachment" "lambda_upload_attach" {
  role       = aws_iam_role.lambda_upload_role.name
  policy_arn = aws_iam_policy.lambda_upload_policy.arn
  
  depends_on = [aws_iam_role.lambda_upload_role, aws_iam_policy.lambda_upload_policy]
}

resource "aws_iam_role" "lambda_status_role" {
  name = "${var.prefix}-lambda-status-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_status_policy" {
  name        = "${var.prefix}-lambda-status-policy-${var.environment}"
  description = "Policy for status Lambda"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = ["s3:PutObject", "s3:GetObject"],
        Effect   = "Allow",
        Resource = [
          "${aws_s3_bucket.pdf_storage.arn}/*",
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
  
  depends_on = [aws_s3_bucket.pdf_storage, aws_s3_bucket.website]
}

resource "aws_iam_role_policy_attachment" "lambda_status_attach" {
  role       = aws_iam_role.lambda_status_role.name
  policy_arn = aws_iam_policy.lambda_status_policy.arn
  
  depends_on = [aws_iam_role.lambda_status_role, aws_iam_policy.lambda_status_policy]
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.prefix}-ecs-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  
  depends_on = [aws_iam_role.ecs_execution_role]
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecs-task-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.prefix}-ecs-task-policy-${var.environment}"
  description = "Policy for ECS tasks"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"],
        Effect   = "Allow",
        Resource = aws_sqs_queue.ocr_queue.arn
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.pdf_storage.arn}/*"
      },
      {
        Action   = ["sns:Publish"],
        Effect   = "Allow",
        Resource = aws_sns_topic.ocr_notifications.arn
      }
    ]
  })
  
  depends_on = [aws_sqs_queue.ocr_queue, aws_s3_bucket.pdf_storage, aws_sns_topic.ocr_notifications]
}

resource "aws_iam_role_policy_attachment" "ecs_task_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
  
  depends_on = [aws_iam_role.ecs_task_role, aws_iam_policy.ecs_task_policy]
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.prefix}-lambda-sg-${var.environment}"
  description = "Security group for Lambda functions"
  vpc_id      = local.create_vpc ? aws_vpc.main["vpc"].id : var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  depends_on = [aws_vpc.main]
}

resource "aws_security_group" "ecs_sg" {
  name        = "${var.prefix}-ecs-sg-${var.environment}"
  description = "Security group for ECS tasks"
  vpc_id      = local.create_vpc ? aws_vpc.main["vpc"].id : var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  depends_on = [aws_vpc.main]
}
