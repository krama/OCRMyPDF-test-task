# ┏━╸┏━╸┏━┓
# ┣╸ ┃  ┣┳┛
# ┗━╸┗━╸╹┗╸

resource "aws_ecr_repository" "ocrmypdf" {
  name                 = "${var.prefix}-ocrmypdf-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_delete_ecr
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "docker_pull_and_push" {
  count = var.use_localstack ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      docker pull ${var.docker_hub_image}
      docker tag ${var.docker_hub_image} ${aws_ecr_repository.ocrmypdf.repository_url}:latest
      aws --endpoint-url=${var.localstack_endpoint} ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.ocrmypdf.repository_url}
      docker push ${aws_ecr_repository.ocrmypdf.repository_url}:latest
    EOT
    
    environment = {
      AWS_ACCESS_KEY_ID     = var.localstack_access_key
      AWS_SECRET_ACCESS_KEY = var.localstack_secret_key
      AWS_DEFAULT_REGION    = var.region
    }
  }

  triggers = {
    docker_image = var.docker_hub_image
    repository   = aws_ecr_repository.ocrmypdf.repository_url
    time         = timestamp()
  }

  depends_on = [aws_ecr_repository.ocrmypdf]
}

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
}