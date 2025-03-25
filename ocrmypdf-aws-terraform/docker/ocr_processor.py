#!/usr/bin/env python3
"""OCR Processor Module.
This module processes PDF files using OCRMyPDF: downloads from S3, applies OCR,
uploads the result to S3, and sends notifications via SNS.
"""

import json  # JSON operations
import os  # OS operations
import time  # Time functions
import subprocess  # Run shell commands
import boto3  # AWS SDK
import logging  # Logging
import tempfile  # Temporary file management
from urllib.parse import urlparse  # URL parsing

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Initialize AWS clients
s3 = boto3.client('s3')  # S3 client
sqs = boto3.client('sqs')  # SQS client
sns = boto3.client('sns')  # SNS client

# Environment variables
SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']  # SQS Queue URL
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']  # SNS Topic ARN

def parse_s3_path(s3_path):
    """Parse S3 path in the format s3://bucket/key.

    Args:
        s3_path (str): The S3 path.

    Returns:
        tuple: (bucket, key).

    Raises:
        ValueError: If scheme is not 's3'.
    """
    parsed = urlparse(s3_path)
    if parsed.scheme != 's3':
        raise ValueError(f"Unsupported scheme: {parsed.scheme}")
    bucket = parsed.netloc
    key = parsed.path.lstrip('/')
    return bucket, key

def download_from_s3(s3_path, local_path):
    """Download a file from S3.

    Args:
        s3_path (str): S3 path (s3://bucket/key).
        local_path (str): Local file path.
    """
    bucket, key = parse_s3_path(s3_path)
    logger.info(f"Downloading {key} from bucket {bucket} to {local_path}")
    s3.download_file(bucket, key, local_path)

def upload_to_s3(local_path, s3_path):
    """Upload a file to S3.

    Args:
        local_path (str): Local file path.
        s3_path (str): S3 destination path.
    """
    bucket, key = parse_s3_path(s3_path)
    logger.info(f"Uploading {local_path} to {bucket}/{key}")
    s3.upload_file(local_path, bucket, key, ExtraArgs={'ContentType': 'application/pdf'})

def process_pdf(input_path, output_path, params):
    """Process a PDF file using OCRMyPDF.

    Args:
        input_path (str): Path to input PDF.
        output_path (str): Path for output PDF.
        params (dict): OCR parameters (e.g., language, deskew).

    Returns:
        bool: True if OCR is successful.

    Raises:
        Exception: If OCR processing fails.
    """
    cmd = ["ocrmypdf"]
    if params.get("language"):
        cmd.extend(["-l", params["language"]])
    if params.get("deskew", False):
        cmd.append("--deskew")
    cmd.extend([input_path, output_path])
    logger.info(f"Running OCR command: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        logger.error(f"OCR failed: {result.stderr}")
        raise Exception(f"OCR processing failed: {result.stderr}")
    logger.info("OCR completed successfully")
    return True

def send_notification(file_id, status, error=None):
    """Send an SNS notification with the processing status.

    Args:
        file_id (str): Unique file ID.
        status (str): Processing status.
        error (str, optional): Error message if any.
    """
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
    """Process a single SQS message for OCR.

    Downloads the PDF, applies OCR, uploads the result, and sends notifications.

    Args:
        message (dict): SQS message.

    Returns:
        bool: True if processing is successful, else False.
    """
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
        send_notification(file_id, "processing")
        with tempfile.NamedTemporaryFile(suffix=".pdf") as input_file, \
             tempfile.NamedTemporaryFile(suffix=".pdf") as output_file:
            download_from_s3(source, input_file.name)
            process_pdf(input_file.name, output_file.name, ocr_params)
            upload_to_s3(output_file.name, destination)
            send_notification(file_id, "completed")
        return True
    except Exception as e:
        logger.error(f"Error processing file {file_id}: {e}")
        send_notification(file_id, "failed", error=str(e))
        return False

def main():
    """Continuously process messages from the SQS queue."""
    logger.info("Starting OCR processor")
    while True:
        try:
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
                if process_message(message):
                    sqs.delete_message(
                        QueueUrl=SQS_QUEUE_URL,
                        ReceiptHandle=receipt_handle
                    )
                    logger.info(f"Message {message['MessageId']} processed and deleted")
                else:
                    logger.warning(f"Failed to process message {message['MessageId']}")
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
