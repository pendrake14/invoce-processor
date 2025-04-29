terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# API Gateway
resource "aws_apigatewayv2_api" "invoice_api" {
  name          = "invoice-processor-api"
  protocol_type = "HTTP"
  description   = "API para procesamiento de facturas"
}

# SQS Queue
resource "aws_sqs_queue" "invoice_queue" {
  name                      = "invoice-processing-queue"
  delay_seconds            = 0
  max_message_size         = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

# DynamoDB Table
resource "aws_dynamodb_table" "invoices" {
  name           = "invoices"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "invoice_id"

  attribute {
    name = "invoice_id"
    type = "S"
  }
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "invoice-processor-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "invoice-processor-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.invoice_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.invoices.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda function for enqueueing invoices
resource "aws_lambda_function" "enqueue_invoice" {
  filename         = "../src/enqueue_invoce/lambda_function.zip"
  function_name    = "enqueue-invoice"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.invoice_queue.url
    }
  }
}

# Lambda function for processing invoices
resource "aws_lambda_function" "process_invoice" {
  filename         = "../src/process_invoice/lambda_function.zip"
  function_name    = "process-invoice"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.invoices.name
    }
  }
}

# SQS Trigger for process_invoice Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.invoice_queue.arn
  function_name    = aws_lambda_function.process_invoice.arn
  batch_size       = 10
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.invoice_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.enqueue_invoice.invoke_arn
}

resource "aws_apigatewayv2_route" "invoice_route" {
  api_id    = aws_apigatewayv2_api.invoice_api.id
  route_key = "POST /invoice"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.enqueue_invoice.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.invoice_api.execution_arn}/*/*"
}
