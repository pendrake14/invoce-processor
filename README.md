# Invoice Processor - Serverless Application

Este proyecto implementa un procesador de facturas serverless utilizando AWS Lambda, SQS, API Gateway y DynamoDB.

## Arquitectura

El sistema está compuesto por los siguientes componentes:

1. **API Gateway**: Expone un endpoint REST para recibir facturas
2. **Lambda (enqueue_invoice)**: Valida y envía las facturas a una cola SQS
3. **SQS**: Almacena las facturas pendientes de procesamiento
4. **Lambda (process_invoice)**: Procesa las facturas y las guarda en DynamoDB
5. **DynamoDB**: Almacena las facturas procesadas

## Requisitos

- AWS CLI configurado con credenciales válidas
- Terraform >= 1.0.0
- Python 3.9
- Bash

## Instalación

1. Clonar el repositorio
2. Ejecutar el script de empaquetado:
   ```bash
   chmod +x package.sh
   ./package.sh
   ```
3. Inicializar y aplicar la infraestructura con Terraform:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

## Uso

Una vez desplegado, puedes enviar facturas al endpoint de API Gateway. El formato de la factura debe ser:

```json
{
  "invoice_id": "INV-001",
  "customer_name": "Cliente Ejemplo",
  "items": [
    {
      "description": "Producto 1",
      "quantity": 2,
      "price": 10.00
    }
  ],
  "total": 20.00
}
```

## Estructura del Proyecto

```
.
├── src/
│   ├── enqueue_invoce/
│   │   ├── lambda_function.py
│   │   └── requirements.txt
│   └── process_invoice/
│       ├── lambda_function.py
│       └── requirements.txt
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── package.sh
└── README.md
```

## Limpieza

Para eliminar todos los recursos creados:

```bash
cd terraform
terraform destroy
``` 