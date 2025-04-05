# Module for OCRMyPDF security resources

# IAM roles and policies for Lambda function for file uploading
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
  description = "Policy for Lambda function for file uploading"
  
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
        Resource = "${var.pdf_bucket_arn}/*"
      },
      {
        Action   = ["sqs:SendMessage"],
        Effect   = "Allow",
        Resource = var.sqs_queue_arn
      },
      {
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_upload_attach" {
  role       = aws_iam_role.lambda_upload_role.name
  policy_arn = aws_iam_policy.lambda_upload_policy.arn
}

# IAM roles and policies for Lambda function for status updating
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
  description = "Policy for Lambda function for status updating"
  
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
          "${var.pdf_bucket_arn}/*",
          "${var.website_bucket_arn}/*"
        ]
      },
      {
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_status_attach" {
  role       = aws_iam_role.lambda_status_role.name
  policy_arn = aws_iam_policy.lambda_status_policy.arn
}

# IAM roles and policies for ECS tasks
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
  description = "Policy for ECS tasks to process OCR"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"],
        Effect   = "Allow",
        Resource = var.sqs_queue_arn
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject"],
        Effect   = "Allow",
        Resource = "${var.pdf_bucket_arn}/*"
      },
      {
        Action   = ["sns:Publish"],
        Effect   = "Allow",
        Resource = var.sns_topic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# Security groups for Lambda and ECS
resource "aws_security_group" "lambda_sg" {
  name        = "${var.prefix}-lambda-sg-${var.environment}"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.prefix}-lambda-sg"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "${var.prefix}-ecs-sg-${var.environment}"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.prefix}-ecs-sg"
  }
}
