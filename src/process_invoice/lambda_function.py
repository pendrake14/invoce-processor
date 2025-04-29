import json
import os
import boto3
import logging
from decimal import Decimal

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize clients
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def convert_floats_to_decimals(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: convert_floats_to_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_floats_to_decimals(i) for i in obj]
    return obj

def lambda_handler(event, context):
    try:
        logger.info("Received event: %s", event)
        
        # Process each record
        for record in event['Records']:
            # Get the message body
            body = json.loads(record['body'])
            
            # Convert float values to Decimal
            invoice = convert_floats_to_decimals(body)
            
            # Store in DynamoDB
            response = table.put_item(
                Item={
                    'invoice_id': invoice['invoice_id'],
                    'customer_name': invoice['customer_name'],
                    'items': invoice['items'],
                    'total': invoice['total'],
                    'processed_at': Decimal(str(context.get_remaining_time_in_millis()))
                }
            )
            
            logger.info("Invoice processed successfully: %s", invoice['invoice_id'])
            
    except Exception as e:
        logger.error("Error processing invoice: %s", str(e))
        raise 