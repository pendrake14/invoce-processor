#!/bin/bash

# Crear directorio para la capa
mkdir -p src/layer/python

# Crear y activar entorno virtual
cd src/layer
python3.12 -m venv venv
source venv/bin/activate

# Instalar dependencias comunes
pip install -r requirements.txt

# Copiar dependencias al directorio de la capa
cp -r venv/lib/python3.12/site-packages/* python/

# Crear el zip de la capa
zip -r layer.zip python/

# Limpiar
deactivate
rm -rf venv python
cd ../../ 