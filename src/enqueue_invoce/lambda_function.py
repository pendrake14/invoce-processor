import json
import os
import boto3

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
        if 'body' not in event:
            raise ValueError("Missing 'body' in event")
            
        invoice = json.loads(event['body'])
        
        # Validate the invoice
        validate_invoice(invoice)
        
        # Send to SQS
        response = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(invoice)
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Invoice enqueued successfully',
                'message_id': response['MessageId']
            })
        }
        
    except ValueError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': str(e)
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        } 