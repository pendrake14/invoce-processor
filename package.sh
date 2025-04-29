#!/bin/bash

# Lista de funciones Lambda a empaquetar
LAMBDAS=("enqueue_invoce" "process_invoice")

for lambda in "${LAMBDAS[@]}"; do
    echo "Empaquetando $lambda..."
    
    # Entrar al directorio de la función
    cd src/$lambda
    
    # Crear y activar entorno virtual con Python 3.12
    python3.12 -m venv venv
    source venv/bin/activate
    
    # Instalar dependencias
    pip install -r requirements.txt
    
    # Crear directorio temporal y copiar dependencias
    mkdir -p package
    cd package
    cp -r ../venv/lib/python3.12/site-packages/* .
    cp ../lambda_function.py .
    
    # Crear el zip
    zip -r ../lambda_function.zip .
    
    # Limpiar
    cd ..
    deactivate
    rm -rf venv package
    cd ../../
    
    echo "Empaquetado de $lambda completado!"
done

echo "¡Proceso de empaquetado completado!"


