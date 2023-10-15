import boto3
import json
import logging
from enum import Enum
from flask import Response
from pythonjsonlogger import jsonlogger


def Logger(app):
    logger = logging.getLogger(app)
    logHandler = logging.StreamHandler()
    formatter = jsonlogger.JsonFormatter(
        fmt="%(asctime)s %(levelname)s %(name)s %(message)s"
    )

    logHandler.setFormatter(formatter)
    logger.addHandler(logHandler)
    logger.setLevel("DEBUG")
    return logger


_cache: dict = {}

def get_service_client(service_name: str = "lambda"):
    if service_name not in _cache:
        _cache[service_name] = boto3.client(service_name)

    return _cache[service_name]


def send_success_code() -> Response:
    return Response(
        json.dumps({"code": "SUCCESS", "message": "Successful"}),
        status=200,
        mimetype="application/json"
    )

def send_error_code(error_code: Enum) -> Response:
    return Response(
        json.dumps({"code": error_code.name, "message": error_code.value}),
        status=200,
        mimetype="application/json"
    )

def send_json(data: dict, status: int=200) -> Response:
    return Response(
        json.dumps(data),
        status=status,
        mimetype="application/json"
    )