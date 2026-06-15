#!/usr/bin/env bash
set -euo pipefail

# Envia 2 requests POST /process identicos y muestra el header X-Cache de
# cada respuesta. Evidencia esperada: request 1 -> MISS, request 2 -> HIT.
#
# Uso:
#   ./scripts/test_cache.sh <API_ENDPOINT_BASE>
#
# Ejemplo (usando el output de terraform):
#   ./scripts/test_cache.sh "$(terraform output -raw api_endpoint)"

if [ $# -lt 1 ]; then
  echo "Uso: $0 <API_ENDPOINT_BASE>"
  echo "Ejemplo: $0 https://abc123.execute-api.us-east-1.amazonaws.com"
  exit 1
fi

BASE_URL="${1%/}"
URL="${BASE_URL}/process"
PAYLOAD='{"message": "hola sre test", "value": 42}'

RESP1="$(mktemp)"
RESP2="$(mktemp)"
trap 'rm -f "$RESP1" "$RESP2"' EXIT

echo "=== Request 1 (esperado: X-Cache: MISS) ==="
curl -sS -i -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  | tee "$RESP1"
echo

echo "=== Request 2 (esperado: X-Cache: HIT) ==="
curl -sS -i -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  | tee "$RESP2"
echo

echo "=== Resumen ==="
CACHE1="$(grep -i '^x-cache:' "$RESP1" | tr -d '\r' | cut -d' ' -f2)"
CACHE2="$(grep -i '^x-cache:' "$RESP2" | tr -d '\r' | cut -d' ' -f2)"
echo "Request 1 X-Cache: ${CACHE1:-<no encontrado>}"
echo "Request 2 X-Cache: ${CACHE2:-<no encontrado>}"

if [ "$CACHE1" = "MISS" ] && [ "$CACHE2" = "HIT" ]; then
  echo "OK: evidencia MISS -> HIT confirmada"
else
  echo "ATENCION: no se obtuvo el patron MISS -> HIT esperado"
  exit 1
fi
