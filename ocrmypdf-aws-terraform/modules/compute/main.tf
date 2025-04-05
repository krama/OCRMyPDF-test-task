# Module for OCRMyPDF compute resources

# This file imports other files for better organization of the module components
# ECS components are in a separate file ecs.tf
# Lambda functions are in a separate file lambda.tf

# Lambda function file variables (used in lambda.tf)
locals {
  lambda_uploader_filename = "${path.module}/files/file_uploader.py"
  lambda_status_filename   = "${path.module}/files/file_updater.py"
  
  lambda_uploader_zip_path = "${path.module}/files/file_uploader.zip"
  lambda_status_zip_path   = "${path.module}/files/status_updater.zip"
}

# Create a directory for files if it does not exist
resource "null_resource" "create_files_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/files"
  }

  # Use a simpler trigger based on a timestamp
  triggers = {
    # Updated on every Terraform apply
    time = timestamp()
  }
}
