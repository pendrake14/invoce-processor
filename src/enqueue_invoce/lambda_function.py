import json
import os
import boto3
from python_json_logger import JsonFormatter
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = JsonFormatter()
handler = logging.StreamHandler()
handler.setFormatter(formatter)
logger.addHandler(handler)

# Initialize SQS client
sqs = boto3.client('sqs')
queue_url = os.environ['QUEUE_URL']

def validate_invoice(invoice):
    required_fields = ['invoice_id', 'customer_name', 'items', 'total']
    for field in required_fields:
        if field not in invoice:
            raise ValueError(f"Missing required field: {field}")
    
    if not isinstance(invoice['items'], list):
        raise ValueError("Items must be a list")
    
    if not isinstance(invoice['total'], (int, float)):
        raise ValueError("Total must be a number")

def lambda_handler(event, context):
    try:
        # Parse the incoming invoice
        invoice = json.loads(event['body'])
        
        # Validate the invoice
        validate_invoice(invoice)
        
        # Send to SQS
        response = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(invoice)
        )
        
        logger.info("Invoice enqueued successfully", extra={
            "invoice_id": invoice['invoice_id'],
            "message_id": response['MessageId']
        })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Invoice enqueued successfully',
                'message_id': response['MessageId']
            })
        }
        
    except ValueError as e:
        logger.error("Validation error", extra={"error": str(e)})
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': str(e)
            })
        }
    except Exception as e:
        logger.error("Unexpected error", extra={"error": str(e)})
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error'
            })
        } 