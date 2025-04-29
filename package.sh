#!/bin/bash

# Lista de funciones Lambda a empaquetar
LAMBDAS=("enqueue_invoce" "process_invoice")

for lambda in "${LAMBDAS[@]}"; do
    echo "Empaquetando $lambda..."
    
    # Entrar al directorio de la función
    cd src/$lambda
    
    # Crear el zip solo con el código de la función
    zip -r lambda_function.zip lambda_function.py
    
    
    cd ../../
    echo "Empaquetado de $lambda completado!"
done

echo "¡Proceso de empaquetado completado!"


