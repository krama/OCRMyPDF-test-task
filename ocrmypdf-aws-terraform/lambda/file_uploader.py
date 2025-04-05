#!/usr/bin/env python3
"""File Uploader Lambda Module.
This Lambda function processes multipart/form-data requests from API Gateway,
uploads the PDF file to S3, and sends an SQS message to trigger OCR processing.
"""

import json  # JSON operations
import os  # OS operations
import uuid  # Generate unique file IDs
import time  # Time functions
import boto3  # AWS SDK
import base64  # Base64 decoding

# Initialize AWS clients
s3 = boto3.client('s3')  # S3 client
sqs = boto3.client('sqs')  # SQS client

# Environment variables for S3 and SQS
S3_BUCKET = os.environ['S3_BUCKET']  # S3 bucket for file storage
SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']  # SQS Queue URL

def parse_multipart_form(event):
    body = event.get('body', '')
    if event.get('isBase64Encoded', False):
        body = base64.b64decode(body).decode('utf-8')
    content_type = event.get('headers', {}).get('content-type', '')
    if 'boundary=' in content_type:
        boundary = content_type.split('boundary=')[1].strip()
    else:
        return None, {}
    parts = body.split('--' + boundary)
    parts = parts[1:-1]
    file_content = None
    params = {}
    for part in parts:
        if not part.strip():
            continue
        headers_content = part.strip().split('\r\n\r\n', 1)
        if len(headers_content) != 2:
            continue
        headers, content = headers_content
        if 'filename=' in headers:
            file_content = content
        else:
            if 'name=' in headers:
                name = headers.split('name=')[1].split(';')[0].strip('"\'')
                params[name] = content.strip()
    return file_content, params

def handler(event, context):
    try:
        print(f"Received event: {json.dumps(event)}")
        content_type = event.get('headers', {}).get('content-type', '')
        if 'multipart/form-data' in content_type:
            file_content, params = parse_multipart_form(event)
            if not file_content:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'message': 'No file found in request'})
                }
            file_id = str(uuid.uuid4())
            file_name = f"input/{file_id}.pdf"
            s3.put_object(
                Bucket=S3_BUCKET,
                Key=file_name,
                Body=file_content,
                ContentType='application/pdf'
            )
            deskew = params.get('deskew', 'true').lower() == 'true'
            language = params.get('language', 'eng')
            message = {
                'file_id': file_id,
                'source': f"s3://{S3_BUCKET}/{file_name}",
                'destination': f"s3://{S3_BUCKET}/output/{file_id}.pdf",
                'ocr_params': {'language': language, 'deskew': deskew},
                'timestamp': int(time.time())
            }
            sqs.send_message(
                QueueUrl=SQS_QUEUE_URL,
                MessageBody=json.dumps(message)
            )
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'message': 'PDF file uploaded and queued for OCR processing',
                    'file_id': file_id
                })
            }
        else:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Invalid content type, expected multipart/form-data'})
            }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Error processing upload: {str(e)}'})
        }
