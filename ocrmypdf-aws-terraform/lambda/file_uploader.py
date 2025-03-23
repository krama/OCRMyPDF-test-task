import json
import os
import uuid
import time
import boto3
import base64

# Initialize AWS clients
s3 = boto3.client('s3')
sqs = boto3.client('sqs')

# Getting parameters from environment variables
S3_BUCKET = os.environ['S3_BUCKET']
SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']

def parse_multipart_form(event):
    """
    Parse multipart/form-data from API Gateway event
    """
    body = event.get('body', '')
    if event.get('isBase64Encoded', False):
        body = base64.b64decode(body).decode('utf-8')
    
    content_type = event.get('headers', {}).get('content-type', '')
    
    # Extract boundary from Content-Type
    if 'boundary=' in content_type:
        boundary = content_type.split('boundary=')[1].strip()
    else:
        return None, {}
    
    # Split content by boundary
    parts = body.split('--' + boundary)
    
    # Ignore the first and last parts (usually empty)
    parts = parts[1:-1]
    
    # Extract file and parameters
    file_content = None
    params = {}
    
    for part in parts:
        # Skip empty parts
        if not part.strip():
            continue
            
        # Split headers and content
        headers_content = part.strip().split('\r\n\r\n', 1)
        if len(headers_content) != 2:
            continue
            
        headers, content = headers_content
        
        # Check if the part is a file
        if 'filename=' in headers:
            # It's a file
            file_content = content
        else:
            # It's a form parameter
            # Extract parameter name from header
            if 'name=' in headers:
                name = headers.split('name=')[1].split(';')[0].strip('"\'')
                params[name] = content.strip()
    
    return file_content, params

def handler(event, context):
    """Lambda function handler for file upload"""
    try:
        # Log incoming request for debugging
        print(f"Received event: {json.dumps(event)}")
        
        # Process multipart/form-data
        content_type = event.get('headers', {}).get('content-type', '')
        
        if 'multipart/form-data' in content_type:
            # Parse form
            file_content, params = parse_multipart_form(event)
            
            if not file_content:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'message': 'No file found in request'
                    })
                }
            
            # Generate a unique file name
            file_id = str(uuid.uuid4())
            file_name = f"input/{file_id}.pdf"
            
            # Save file to S3
            s3.put_object(
                Bucket=S3_BUCKET,
                Key=file_name,
                Body=file_content,
                ContentType='application/pdf'
            )
            
            # Retrieve additional parameters
            deskew = params.get('deskew', 'true').lower() == 'true'
            language = params.get('language', 'eng')
            
            # Create SQS message
            message = {
                'file_id': file_id,
                'source': f"s3://{S3_BUCKET}/{file_name}",
                'destination': f"s3://{S3_BUCKET}/output/{file_id}.pdf",
                'ocr_params': {
                    'language': language,
                    'deskew': deskew
                },
                'timestamp': int(time.time())
            }
            
            # Send message to SQS
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
                'body': json.dumps({
                    'message': 'Invalid content type, expected multipart/form-data'
                })
            }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': f'Error processing upload: {str(e)}'
            })
        }
