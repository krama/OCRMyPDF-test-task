resource "aws_ecr_repository" "ocrmypdf" {
  name                 = "${var.prefix}-ocrmypdf-${var.environment}" // create ECR repository
  image_tag_mutability = "MUTABLE" // allow mutable tags

  image_scanning_configuration {
    scan_on_push = true // scan on push
  }
}

resource "null_resource" "docker_pull_and_push" {
  count = var.use_docker_hub ? 0 : 1 // only if not using Docker Hub
  
  provisioner "local-exec" {
    command = <<-EOT
      docker pull ${var.docker_hub_image} // pull image from Docker Hub
      docker tag ${var.docker_hub_image} ${aws_ecr_repository.ocrmypdf.repository_url}:latest // tag image for ECR
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.ocrmypdf.repository_url} // login to ECR
      docker push ${aws_ecr_repository.ocrmypdf.repository_url}:latest // push image to ECR
    EOT
  }

  depends_on = [aws_ecr_repository.ocrmypdf] // depends on repository
}

resource "aws_ecr_lifecycle_policy" "ocrmypdf_policy" {
  repository = aws_ecr_repository.ocrmypdf.name // apply to repository
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1, // highest priority
        description  = "Keep last 5 images", // description
        selection = {
          tagStatus   = "any", // any tag
          countType   = "imageCountMoreThan", // count images
          countNumber = 5 // keep 5
        },
        action = {
          type = "expire" // expire images
        }
      }
    ]
  })
  
  depends_on = [aws_ecr_repository.ocrmypdf, null_resource.docker_pull_and_push] // depends on repository and image push
}
