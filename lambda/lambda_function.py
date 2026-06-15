import datetime
import hashlib
import json
import logging
import os
import uuid

import boto3
import redis

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REDIS_HOST = os.environ["REDIS_HOST"]
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
BUCKET_NAME = os.environ["BUCKET_NAME"]
CACHE_TTL = int(os.environ.get("CACHE_TTL", "60"))

s3_client = boto3.client("s3")

# Se crea una sola vez, fuera del handler, para reutilizar la conexion a
# Redis cuando Lambda reusa el mismo entorno entre invocaciones ("warm").
redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    decode_responses=True,
    socket_timeout=3,
    socket_connect_timeout=3,
)


def build_cache_key(event):
    """Genera una clave unica (hash) a partir del contenido del request."""
    body = event.get("body") or ""
    query_params = event.get("queryStringParameters") or {}
    raw = json.dumps(
        {"body": body, "query": query_params},
        sort_keys=True,
        separators=(",", ":"),
    )
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    return f"cache:process:{digest}"


def process_payload(event):
    """"Procesa" el request: calcula un hash SHA-256 y el texto al reves."""
    body = event.get("body") or ""
    digest = hashlib.sha256(body.encode("utf-8")).hexdigest()
    return {
        "input_length": len(body),
        "sha256": digest,
        "reversed_preview": body[::-1][:200],
    }


def save_result_to_s3(result):
    """Guarda el resultado en results/<fecha>/<id>.json y devuelve esa ruta (key)."""
    today = datetime.datetime.utcnow().strftime("%Y-%m-%d")
    object_id = str(uuid.uuid4())
    key = f"results/{today}/{object_id}.json"

    s3_client.put_object(
        Bucket=BUCKET_NAME,
        Key=key,
        Body=json.dumps(result).encode("utf-8"),
        ContentType="application/json",
    )
    return key


def _response(status_code, body_dict, cache_status):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "X-Cache": cache_status,
        },
        "body": json.dumps(body_dict),
    }


def lambda_handler(event, context):
    try:
        cache_key = build_cache_key(event)

        cached_value = redis_client.get(cache_key)

        if cached_value is not None:
            logger.info("Cache HIT para key=%s", cache_key)
            return _response(200, json.loads(cached_value), "HIT")

        logger.info("Cache MISS para key=%s", cache_key)

        result = process_payload(event)
        result["s3_key"] = save_result_to_s3(result)

        redis_client.set(cache_key, json.dumps(result), ex=CACHE_TTL)

        return _response(200, result, "MISS")

    except Exception as exc:
        logger.exception("Error procesando request")
        return _response(
            500,
            {"error": "Error interno procesando la solicitud", "detail": str(exc)},
            "MISS",
        )
