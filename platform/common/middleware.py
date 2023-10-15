import os
import jwt
from typing import Union
from typing import Callable
from functools import wraps

from flask import abort
from flask import request

from common.dal.client import psql_client
from common.services import secret
from common.constants import SecretsNameEnum
from aws_lambda_powertools.middleware_factory import lambda_handler_decorator


def _capitalize_all_headers(event):
    uppercase_headers = {}
    for name, value in event["headers"].items():
        uppercase_headers[name.upper()] = value

    event["headers"] = uppercase_headers


@lambda_handler_decorator
def api_middleware(handler, event, context):

    _capitalize_all_headers(event)

    if not psql_client.get_db():
        psql_client.connect()

    response = handler(event, context)
    if os.environ['STAGE'] != 'dev':
        return response

    if psql_client.get_db():
        psql_client.get_db().close()

    return response


def appuser_required(handler: Callable):
    @wraps(handler)
    def decorated(*args: tuple, **kwargs: dict) -> Callable:

        access_token: Union[str, None] = None
        if "AUTHORIZATION" in request.headers:
            access_token = request.headers["AUTHORIZATION"].split(" ")[1]

        if not access_token:
            return abort(401)

        try:
            payload = jwt.decode(
                access_token,
                secret.get_jwt_secret(SecretsNameEnum.APP_JWT_CREDS.name),
                algorithms=["HS256"]
            )
        except Exception as e:
            return abort(401)

        return handler(payload["user"], *args, **kwargs)

    return decorated