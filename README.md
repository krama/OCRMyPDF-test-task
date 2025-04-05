# OCRMyPDF AWS Terraform Infrastructure

This repository contains Terraform code for deploying a PDF OCR processing system in AWS.

## System Architecture

See diagram.svg or https://www.mermaidchart.com/raw/9881c372-d943-41f3-913c-3ea72d2328b5?theme=dark&version=v0.1&format=svg

### Infrastructure Components:

- **API Gateway**: API for uploading PDF files
- **Lambda**: Functions for file upload and status updates
- **S3**: Storage for PDF files and web interface
- **SQS**: Queue for OCR processing tasks
- **SNS**: Notifications about processing status
- **ECS**: Containers for OCR processing
- **ECR**: Container repository
- **CloudWatch**: Logging and monitoring
- **IAM**: Management of roles and access policies

### Modular Structure:

```
ocrmypdf-aws-terraform/
├── main.tf                 # Main file that combines all modules
├── variables.tf            # Main project variables
├── outputs.tf              # Project output variables
├── backend.tf              # Remote state configuration
├── versions.tf             # Provider versions
├── providers.tf            # Provider configuration
├── locals.tf               # Local variables
├── environments/           # Variables for different environments
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/                # Terraform modules
│   ├── networking/         # VPC, subnets, routing management
│   ├── storage/            # S3 buckets for files and website
│   ├── messaging/          # SQS queues and SNS topics
│   ├── container/          # ECR repositories for containers
│   ├── compute/            # ECS clusters and Lambda functions
│   ├── security/           # IAM roles and security policies
│   ├── api/                # API Gateway configuration
│   └── frontend/           # Web interface
└── docker/                 # Docker container files
    ├── Dockerfile
    └── ocr_processor.py
```

## Getting Started

### Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with administrator privileges
- Docker (for local development with LocalStack)
- Python >= 3.9

### Local Development with LocalStack

1. Start LocalStack:
   ```bash
   docker run -d --name localstack -p 4566:4566 -p 4571:4571 localstack/localstack
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Apply the configuration for the dev environment:
   ```bash
   terraform apply -var-file=environments/dev.tfvars
   ```

### Deploying to AWS Cloud

1. Configure AWS CLI:
   ```bash
   aws configure
   ```

2. Set up a backend for state (optional, uncomment in backend.tf):
   ```bash
   # Create an S3 bucket and DynamoDB table for locks
   aws s3 mb s3://ocrmypdf-terraform-state --region eu-central-2
   aws dynamodb create-table --table-name ocrmypdf-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region eu-central-2
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. For staging:
   ```bash
   terraform workspace new staging
   terraform apply -var-file=environments/staging.tfvars
   ```

5. For production:
   ```bash
   terraform workspace new prod
   terraform apply -var-file=environments/prod.tfvars
   ```

## Module Structure

### networking
Creates a VPC, public and private subnets, NAT Gateway and Internet Gateway. Configures routing tables for internet access.

### storage
Manages S3 buckets for storing PDF files and the web interface. Includes lifecycle configuration and website hosting.

### messaging
Sets up SQS queues for OCR processing tasks and SNS topics for status notifications.

### container
Manages the ECR repository for Docker images and their lifecycle.

### compute
Creates Lambda functions for file uploading and status updates, as well as an ECS cluster for OCR processing and configures auto-scaling.

### security
Configures IAM roles and access policies for all services, as well as security groups.

### api
Creates and configures API Gateway for interaction with the system through REST API.

### frontend
Manages the content of the web interface uploaded to an S3 bucket with configured hosting.

## Using the Web Interface

After deployment, you will get the web interface URL in the output variables:

```bash
terraform output website_url
```

Through the web interface you can:
1. Upload a PDF file
2. Enable/disable automatic alignment (deskew)
3. Track the status of file processing
4. Download processed PDF files with recognized text

## Cleaning Up Resources

To delete all created resources, run:

```bash
terraform destroy -var-file=environments/<environment>.tfvars
```

## Security Structure

The system uses the following security mechanisms:
- IAM roles with minimal privileges following the principle of least privilege
- Separation into private and public subnets
- Security groups for traffic restriction
- Temporary file storage with automatic deletion
- CORS settings for secure web requests
