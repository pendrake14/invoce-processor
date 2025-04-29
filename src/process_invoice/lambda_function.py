import json
import os
import boto3
from python_json_logger import JsonFormatter
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = JsonFormatter()
handler = logging.StreamHandler()
handler.setFormatter(formatter)
logger.addHandler(handler)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def calculate_tax(total):
    # Simple tax calculation (19% VAT)
    return total * 0.19

def process_invoice(invoice):
    # Add processing timestamp
    invoice['processed_at'] = datetime.utcnow().isoformat()
    
    # Calculate tax
    invoice['tax'] = calculate_tax(invoice['total'])
    
    # Calculate total with tax
    invoice['total_with_tax'] = invoice['total'] + invoice['tax']
    
    return invoice

def lambda_handler(event, context):
    try:
        # Process each record from SQS
        for record in event['Records']:
            invoice = json.loads(record['body'])
            
            # Process the invoice
            processed_invoice = process_invoice(invoice)
            
            # Save to DynamoDB
            table.put_item(Item=processed_invoice)
            
            logger.info("Invoice processed successfully", extra={
                "invoice_id": invoice['invoice_id'],
                "total": invoice['total'],
                "tax": invoice['tax']
            })
            
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Invoices processed successfully'
            })
        }
        
    except Exception as e:
        logger.error("Error processing invoice", extra={"error": str(e)})
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error'
            })
        } 