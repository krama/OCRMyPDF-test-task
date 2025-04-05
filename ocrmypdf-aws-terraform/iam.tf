#  ╦╔═╗╔╦╗  ╔═╗╔═╗╦═╗  ╦  ╔═╗╔╦╗╔╗ ╔╦╗╔═╗  ╦ ╦╔═╗╦  ╔═╗╔═╗╔╦╗╔═╗╦═╗
#  ║╠═╣║║║  ╠╣ ║ ║╠╦╝  ║  ╠═╣║║║╠╩╗ ║║╠═╣  ║ ║╠═╝║  ║ ║╠═╣ ║║║╣ ╠╦╝
#  ╩╩ ╩╩ ╩  ╚  ╚═╝╩╚═  ╩═╝╩ ╩╩ ╩╚═╝═╩╝╩ ╩  ╚═╝╩  ╩═╝╚═╝╩ ╩═╩╝╚═╝╩╚═
resource "aws_iam_role" "lambda_upload_role" {
  name = "${var.prefix}-lambda-upload-role-${var.environment}"  # Role name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",  # Allow Lambda service
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# IAM policy for Lambda file uploader (logs, S3, SQS, EC2)
resource "aws_iam_policy" "lambda_upload_policy" {
  name        = "${var.prefix}-lambda-upload-policy-${var.environment}"  # Policy name
  description = "Policy for upload Lambda"  # Policy description
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
}

# Attach Lambda uploader policy to its role
resource "aws_iam_role_policy_attachment" "lambda_upload_attach" {
  role       = aws_iam_role.lambda_upload_role.name
  policy_arn = aws_iam_policy.lambda_upload_policy.arn
}

#  ╦╔═╗╔╦╗  ╔═╗╔═╗╦═╗  ╦  ╔═╗╔╦╗╔╗ ╔╦╗╔═╗  ╦ ╦╔═╗╔╦╗╔═╗╔╦╗╔═╗╦═╗
#  ║╠═╣║║║  ╠╣ ║ ║╠╦╝  ║  ╠═╣║║║╠╩╗ ║║╠═╣  ║ ║╠═╝ ║║╠═╣ ║ ║╣ ╠╦╝
#  ╩╩ ╩╩ ╩  ╚  ╚═╝╩╚═  ╩═╝╩ ╩╩ ╩╚═╝═╩╝╩ ╩  ╚═╝╩  ═╩╝╩ ╩ ╩ ╚═╝╩╚═
resource "aws_iam_role" "lambda_status_role" {
  name = "${var.prefix}-lambda-status-role-${var.environment}"  # Role name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",  # Allow Lambda service
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# IAM policy for Lambda status updater (logs, S3, EC2)
resource "aws_iam_policy" "lambda_status_policy" {
  name        = "${var.prefix}-lambda-status-policy-${var.environment}"  # Policy name
  description = "Policy for status Lambda"  # Policy description
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
}

# Attach Lambda status policy to its role
resource "aws_iam_role_policy_attachment" "lambda_status_attach" {
  role       = aws_iam_role.lambda_status_role.name
  policy_arn = aws_iam_policy.lambda_status_policy.arn
}

#  ╦╔═╗╔╦╗  ╔═╗╔═╗╦═╗  ╔═╗╔═╗╔═╗  ╔╦╗╔═╗╔═╗╦╔═
#  ║╠═╣║║║  ╠╣ ║ ║╠╦╝  ║╣ ║  ╚═╗   ║ ╠═╣╚═╗╠╩╗
#  ╩╩ ╩╩ ╩  ╚  ╚═╝╩╚═  ╚═╝╚═╝╚═╝   ╩ ╩ ╩╚═╝╩ ╩
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.prefix}-ecs-execution-role-${var.environment}"  # Role name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",  # Allow ECS tasks
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach standard ECS task execution policy
resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create IAM role for ECS tasks (access to SQS, S3, SNS)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecs-task-role-${var.environment}"  # Role name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",  # Allow ECS tasks
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# IAM policy for ECS tasks
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.prefix}-ecs-task-policy-${var.environment}"  # Policy name
  description = "Policy for ECS tasks"  # Policy description
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
}

# Attach ECS task policy to its role
resource "aws_iam_role_policy_attachment" "ecs_task_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

#  ╔═╗╔═╗╔═╗╦ ╦╦═╗╦╔╦╗╦ ╦  ╔═╗╦═╗╔═╗╦ ╦╔═╗  ╦  ╔═╗╔╦╗╔╗ ╔╦╗╔═╗
#  ╚═╗║╣ ║  ║ ║╠╦╝║ ║ ╚╦╝  ║ ╦╠╦╝║ ║║ ║╠═╝  ║  ╠═╣║║║╠╩╗ ║║╠═╣
#  ╚═╝╚═╝╚═╝╚═╝╩╚═╩ ╩  ╩   ╚═╝╩╚═╚═╝╚═╝╩    ╩═╝╩ ╩╩ ╩╚═╝═╩╝╩ ╩
resource "aws_security_group" "lambda_sg" {
  name        = "${var.prefix}-lambda-sg-${var.environment}"  # SG name
  description = "Security group for Lambda functions"  # SG description
  vpc_id      = var.vpc_id != null ? var.vpc_id : aws_vpc.main[0].id  # VPC ID

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#  ╔═╗╔═╗╔═╗╦ ╦╦═╗╦╔╦╗╦ ╦  ╔═╗╦═╗╔═╗╦ ╦╔═╗  ╔═╗╔═╗╔═╗
#  ╚═╗║╣ ║  ║ ║╠╦╝║ ║ ╚╦╝  ║ ╦╠╦╝║ ║║ ║╠═╝  ║╣ ║  ╚═╗
#  ╚═╝╚═╝╚═╝╚═╝╩╚═╩ ╩  ╩   ╚═╝╩╚═╚═╝╚═╝╩    ╚═╝╚═╝╚═╝
resource "aws_security_group" "ecs_sg" {
  name        = "${var.prefix}-ecs-sg-${var.environment}"  # SG name
  description = "Security group for ECS tasks"  # SG description
  vpc_id      = var.vpc_id != null ? var.vpc_id : aws_vpc.main[0].id  # VPC ID

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}
