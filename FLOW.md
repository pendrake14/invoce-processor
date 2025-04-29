sequenceDiagram
    participant Client
    participant API Gateway
    participant Lambda Enqueue
    participant SQS
    participant Lambda Process
    participant DynamoDB

    Client->>API Gateway: POST /invoice
    API Gateway->>Lambda Enqueue: Invoke
    Lambda Enqueue->>SQS: Send Message
    SQS->>Lambda Process: Trigger
    Lambda Process->>DynamoDB: Put Item

    Note over Lambda Enqueue: Validates invoice<br/>and enqueues
    Note over Lambda Process: Converts floats to Decimal<br/>and stores in DynamoDB