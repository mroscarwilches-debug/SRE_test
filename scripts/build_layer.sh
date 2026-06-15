#!/usr/bin/env bash
set -euo pipefail

# Instala redis-py dentro de un contenedor Docker que imita el entorno real
# de Lambda (Linux x86_64, Python 3.12), usando la imagen oficial de AWS SAM.
# Asi la libreria funciona bien sin importar el sistema operativo donde se
# desarrolle.
#
# Uso: ./scripts/build_layer.sh
# Hay que correrlo ANTES de `terraform apply` (y de nuevo si cambia
# layer/requirements.txt).

cd "$(dirname "$0")/.."

rm -rf layer/python
mkdir -p layer/python

# pwd -W (Git Bash) da la ruta en formato Windows (D:/...), que Docker Desktop
# entiende directamente. MSYS_NO_PATHCONV evita que Git Bash reescriba las
# rutas /var/task/... (destino dentro del contenedor) como rutas de Windows.
HOST_LAYER_DIR="$(pwd -W 2>/dev/null || pwd)/layer"

MSYS_NO_PATHCONV=1 docker run --rm \
  --entrypoint "" \
  -v "${HOST_LAYER_DIR}:/var/task" \
  public.ecr.aws/sam/build-python3.12 \
  pip install -r /var/task/requirements.txt -t /var/task/python --no-cache-dir

echo "Layer construida en layer/python/"
