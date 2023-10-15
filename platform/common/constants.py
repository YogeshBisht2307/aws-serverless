import os
from enum import Enum


class SecretsNameEnum(Enum):
    WEB_JWT_CREDS = f"/config/kodeweich/{os.environ['STAGE']}-webAppJwt"
    APP_DB_CREDS = f"/config/kodeweich/{os.environ['STAGE']}-blogDB"
    EMAIL_CREDS = f"/config/kodeweich/{os.environ['STAGE']}-email"
    SMS_CREDS = f"/config/kodeweich/{os.environ['STAGE']}-sms"
    FIREBASE_CREDS = f"/config/kodeweich/{os.environ['STAGE']}-firebase"


class ErrorCodes(Enum):
    AUTH_FAILURE  = "Auth failure"
    INVALID_INPUT = "Invalid input"
    SERVER_ERROR = "Server Error"
    NOT_FOUND = "Not found"
