# Configuration of Terraform backend

# To use S3 as a backend, uncomment this block and fill in the appropriate parameters

terraform {
  # backend "s3" {
  #   bucket         = "ocrmypdf-terraform-state"
  #   key            = "ocrmypdf/terraform.tfstate"
  #   region         = "eu-central-2"
  #   encrypt        = true
  #   dynamodb_table = "ocrmypdf-terraform-locks"
  # }
}

# To create the infrastructure for the backend (S3 bucket and DynamoDB table)
# use a separate Terraform application or create them manually.

# Example code for creating the backend infrastructure:

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "ocrmypdf-terraform-state"
#   versioning {
#     enabled = true
#   }
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
# }

# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "ocrmypdf-terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }
