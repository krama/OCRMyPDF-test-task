import json
import os
import time
import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3')

S3_BUCKET = os.environ['S3_BUCKET']
S3_WEBSITE_BUCKET = os.environ.get('S3_WEBSITE_BUCKET', '')

def handler(event, context):
    try:
        print(f"Received event: {json.dumps(event)}")

        message = json.loads(event['Records'][0]['Sns']['Message'])
        file_id = message.get('file_id')
        status = message.get('status')

        if not file_id or not status:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Invalid message format'})
            }

        if not S3_WEBSITE_BUCKET:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Missing website bucket'})
            }

        status_file = "status/status.json"

        # Getting current status
        try:
            response = s3.get_object(Bucket=S3_WEBSITE_BUCKET, Key=status_file)
            status_data = json.loads(response['Body'].read().decode('utf-8'))
        except ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchKey':
                print("Status file not found, creating new")
                status_data = {'files': {}}
            else:
                raise

        # Updating status
        status_data['files'][file_id] = {
            'status': status,
            'updated_at': int(time.time()),
            'output_url': f"output/{file_id}.pdf" if status == 'completed' else None
        }

        # Writing status.json in the "status/" directory
        s3.put_object(
            Bucket=S3_WEBSITE_BUCKET,
            Key=status_file,
            Body=json.dumps(status_data),
            ContentType='application/json',
            CacheControl='no-cache'
        )

        print(f"Status updated for {file_id}: {status}")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': f'Status updated for {file_id}'})
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Error: {str(e)}'})
        }

