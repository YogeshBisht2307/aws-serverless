import os
import json
from common.base import Logger
from common.base import get_service_client

logger = Logger("SecretService")

_cache: dict = {}

def get_jwt_secret(secret_name: str) -> str:
    if os.environ['STAGE'] == "dev":
        return json.dumps({"value": "VvOU1LErS6ryrAtqczYqlprFhFmKOoNJ"})
    
    if secret_name in _cache:
        return _cache[secret_name]

    response = get_service_client().invoke(
        FunctionName=os.environ['SECRET_HANDLER'],
        InvocationType='RequestResponse',
        Payload=json.dumps({"type": 1, "data": {"secrets": [secret_name]}})
    )

    try:
        result = json.load(response['Payload'])
        _, secrets = result.get("status"), result.get("content")
        _cache[secret_name] = secrets.get(secret_name)
    except (ValueError, TypeError) as error:
        logger.error(str(error))
        return json.dumps({"value": ""})

    return _cache[secret_name]


def get_secrets(secrets: list) -> tuple:
    cache_miss: list = []
    cache_hit: dict = {}
    for secret_name in secrets:
        if secret_name not in _cache:
            cache_miss.append(secret_name)
        else:
            cache_hit[secret_name] = _cache.get(secret_name)

    response = get_service_client().invoke(
        FunctionName=os.environ['SECRET_HANDLER'],
        InvocationType='RequestResponse',
        Payload=json.dumps({"type": 1, "data": {"secrets": cache_miss}})
    )

    try:
        result = json.load(response['Payload'])
        status, secrets_map = result.get("status"), result.get("content")
        if not status:
            return status, secrets

        for secret_name in cache_miss:
            cache_hit[secret_name] = secrets_map.get(secret_name)

        return status, cache_hit

    except (ValueError, TypeError) as error:
        logger.error(str(error))
        return False, {}
