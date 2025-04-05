#!/usr/bin/env python3
"""
OCR Processor Module.

This module processes PDF files using OCRMyPDF:
downloads from S3, applies OCR, uploads the result to S3,
and sends notifications via SNS.
"""

import json
import os
import time
import subprocess
import boto3
import logging
import tempfile
from urllib.parse import urlparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Initialize AWS clients
s3_client = boto3.client('s3')
sqs_client = boto3.client('sqs')
sns_client = boto3.client('sns')

# Environment variables
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

if not SQS_QUEUE_URL or not SNS_TOPIC_ARN:
    logger.error("Required environment variables are missing: SQS_QUEUE_URL or SNS_TOPIC_ARN")
    exit(1)

def parse_s3_path(s3_path):
    """Parse S3 URL into bucket and key."""
    parsed = urlparse(s3_path)
    if parsed.scheme != 's3':
        raise ValueError(f"Unsupported scheme: {parsed.scheme}")
    return parsed.netloc, parsed.path.lstrip('/')

def download_from_s3(s3_path, local_path):
    """Download file from S3 to local path."""
    bucket, key = parse_s3_path(s3_path)
    logger.info(f"Downloading s3://{bucket}/{key} to {local_path}")
    s3_client.download_file(bucket, key, local_path)

def upload_to_s3(local_path, s3_path):
    """Upload local file to S3."""
    bucket, key = parse_s3_path(s3_path)
    logger.info(f"Uploading {local_path} to s3://{bucket}/{key}")
    s3_client.upload_file(local_path, bucket, key, ExtraArgs={'ContentType': 'application/pdf'})

def process_pdf(input_path, output_path, params):
    """Run OCR process on PDF using ocrmypdf."""
    cmd = ["ocrmypdf"]
    if language := params.get("language"):
        cmd.extend(["-l", language])
    if params.get("deskew", False):
        cmd.append("--deskew")
    cmd.extend([input_path, output_path])
    logger.info(f"Executing OCR command: {' '.join(cmd)}")
    try:
        # Automatically raises CalledProcessError if command fails
        subprocess.run(cmd, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as e:
        logger.error(f"OCR failed: {e.stderr}")
        raise Exception(f"OCR processing failed: {e.stderr}") from e
    logger.info("OCR processing completed successfully")

def send_notification(file_id, status, error=None):
    """Send processing status notification via SNS."""
    message = {
        "file_id": file_id,
        "status": status,
        "timestamp": int(time.time())
    }
    if error:
        message["error"] = str(error)
    try:
        logger.info(f"Sending notification for file {file_id} with status: {status}")
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(message),
            Subject=f"OCR Processing {status.capitalize()}"
        )
    except Exception as e:
        logger.error(f"Failed to send SNS notification: {e}")

def process_message(message):
    """Process an SQS message."""
    file_id = None
    try:
        logger.info(f"Processing message: {message.get('MessageId')}")
        data = json.loads(message['Body'])
        file_id = data.get('file_id')
        source = data.get('source')
        destination = data.get('destination')
        ocr_params = data.get('ocr_params', {})

        if not all([file_id, source, destination]):
            logger.error(f"Invalid message format: {data}")
            return False

        send_notification(file_id, "processing")

        with tempfile.NamedTemporaryFile(suffix=".pdf") as input_file, \
             tempfile.NamedTemporaryFile(suffix=".pdf") as output_file:
            download_from_s3(source, input_file.name)
            process_pdf(input_file.name, output_file.name, ocr_params)
            upload_to_s3(output_file.name, destination)
            send_notification(file_id, "completed")

        return True
    except Exception as e:
        logger.exception(f"Error processing file {file_id}: {e}")
        if file_id:
            send_notification(file_id, "failed", error=e)
        return False

def poll_messages():
    """Continuously poll SQS for messages and process them."""
    logger.info("Starting OCR processor")
    while True:
        try:
            response = sqs_client.receive_message(
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
                if process_message(message):
                    sqs_client.delete_message(
                        QueueUrl=SQS_QUEUE_URL,
                        ReceiptHandle=receipt_handle
                    )
                    logger.info(f"Message {message.get('MessageId')} processed and deleted")
                else:
                    logger.warning(f"Failed to process message {message.get('MessageId')}")
        except Exception as e:
            logger.exception(f"Error in polling loop: {e}")
            time.sleep(5)

def main():
    poll_messages()

if __name__ == "__main__":
    main()
