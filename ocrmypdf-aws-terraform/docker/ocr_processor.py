#!/usr/bin/env python3
import json
import os
import time
import subprocess
import boto3
import logging
from urllib.parse import urlparse

# Set up logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Initialize AWS clients
s3 = boto3.client('s3')
sqs = boto3.client('sqs')
sns = boto3.client('sns')

# Get environment variables
SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def parse_s3_path(s3_path):
    """Parse S3 path in the format s3://bucket/key"""
    parsed = urlparse(s3_path)
    if parsed.scheme != 's3':
        raise ValueError(f"Unsupported scheme: {parsed.scheme}")
    
    bucket = parsed.netloc
    key = parsed.path.lstrip('/')
    return bucket, key

def download_from_s3(s3_path, local_path):
    """Download file from S3"""
    bucket, key = parse_s3_path(s3_path)
    logger.info(f"Downloading {key} from bucket {bucket} to {local_path}")
    s3.download_file(bucket, key, local_path)

def upload_to_s3(local_path, s3_path):
    """Upload file to S3"""
    bucket, key = parse_s3_path(s3_path)
    logger.info(f"Uploading {local_path} to {bucket}/{key}")
    s3.upload_file(local_path, bucket, key, ExtraArgs={'ContentType': 'application/pdf'})

def process_pdf(input_path, output_path, params):
    """Process PDF with OCRMyPDF"""
    cmd = ["ocrmypdf"]
    
    # Add OCR parameters
    if params.get("language"):
        cmd.extend(["-l", params["language"]])
    if params.get("deskew", False):
        cmd.append("--deskew")
    
    # Add file paths
    cmd.extend([input_path, output_path])
    
    logger.info(f"Running OCR command: {' '.join(cmd)}")
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        logger.error(f"OCR failed: {result.stderr}")
        raise Exception(f"OCR processing failed: {result.stderr}")
    
    logger.info(f"OCR completed successfully")
    return True

def send_notification(file_id, status, error=None):
    """Send notification about processing status"""
    message = {
        "file_id": file_id,
        "status": status,
        "timestamp": int(time.time())
    }
    
    if error:
        message["error"] = str(error)
    
    logger.info(f"Sending notification for file {file_id}: {status}")
    
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps(message),
        Subject=f"OCR Processing {status.capitalize()}"
    )

def process_message(message):
    """Process message from SQS"""
    try:
        logger.info(f"Processing message: {message['MessageId']}")
        data = json.loads(message['Body'])
        file_id = data.get('file_id')
        source = data.get('source')
        destination = data.get('destination')
        ocr_params = data.get('ocr_params', {})
        
        if not file_id or not source or not destination:
            logger.error(f"Invalid message format: {data}")
            return False
        
        # Create temporary files
        input_path = f"/tmp/{file_id}_input.pdf"
        output_path = f"/tmp/{file_id}_output.pdf"
        
        try:
            # Send notification about processing start
            send_notification(file_id, "processing")
            
            # Download file
            download_from_s3(source, input_path)
            
            # Process file
            process_pdf(input_path, output_path, ocr_params)
            
            # Upload result
            upload_to_s3(output_path, destination)
            
            # Send notification about processing completion
            send_notification(file_id, "completed")
            
            return True
        
        except Exception as e:
            logger.error(f"Error processing file {file_id}: {str(e)}")
            send_notification(file_id, "failed", error=str(e))
            return False
        
        finally:
            # Delete temporary files
            for path in [input_path, output_path]:
                if os.path.exists(path):
                    os.remove(path)
                    logger.info(f"Removed temporary file: {path}")
    
    except Exception as e:
        logger.error(f"Error processing message: {str(e)}")
        return False

def main():
    """Main loop for processing messages"""
    logger.info("Starting OCR processor")
    
    while True:
        try:
            # Get messages from SQS
            response = sqs.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20,
                VisibilityTimeout=300
            )
            
            messages = response.get('Messages', [])
            
            if not messages:
                logger.info("No messages in queue, waiting...")
                continue
            
            for message in messages:
                receipt_handle = message['ReceiptHandle']
                
                # Process message
                if process_message(message):
                    # Delete message from queue if processing was successful
                    sqs.delete_message(
                        QueueUrl=SQS_QUEUE_URL,
                        ReceiptHandle=receipt_handle
                    )
                    logger.info(f"Message {message['MessageId']} processed and deleted from queue")
                else:
                    logger.warning(f"Failed to process message {message['MessageId']}")
        
        except Exception as e:
            logger.error(f"Error in main loop: {str(e)}")
            time.sleep(5)
if __name__ == "__main__":
    main()
