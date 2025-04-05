#  ╔═╗╔═╗╦═╗
#  ║╣ ║  ╠╦╝
#  ╚═╝╚═╝╩╚═
resource "aws_ecr_repository" "ocrmypdf" {
  name                 = "${var.prefix}-ocrmypdf-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_delete_ecr

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Upload an image to ECR using null_resource
resource "null_resource" "docker_pull_and_push" {
  provisioner "local-exec" {
    command = <<-EOT
      docker pull ${var.docker_hub_image}
      docker tag ${var.docker_hub_image} ${aws_ecr_repository.ocrmypdf.repository_url}:latest
      aws --endpoint-url=http://localhost:4566 ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.ocrmypdf.repository_url}
      docker push ${aws_ecr_repository.ocrmypdf.repository_url}:latest
    EOT
    
    environment = {
      AWS_ACCESS_KEY_ID     = "test"
      AWS_SECRET_ACCESS_KEY = "test"
      AWS_DEFAULT_REGION    = var.region
    }
  }

  depends_on = [aws_ecr_repository.ocrmypdf]
}

# ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "ocrmypdf_policy" {
  repository = aws_ecr_repository.ocrmypdf.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  depends_on = [null_resource.docker_pull_and_push]
}
