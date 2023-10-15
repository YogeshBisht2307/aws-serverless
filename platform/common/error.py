from flask import Blueprint
from common.base import send_json
from common.constants import ErrorCodes


bp_errors = Blueprint('errors', __name__)


@bp_errors.errorhandler(403)
def forbidden(e):
    return send_json({"code": ErrorCodes.AUTH_FAILURE.name, "message": str(e)}, status=403)

@bp_errors.errorhandler(401)
def auth_failure(e):
    return send_json({"code": ErrorCodes.AUTH_FAILURE.name, "message": str(e)}, status=401)

@bp_errors.errorhandler(404)
def not_found(e):
    return send_json({"code": ErrorCodes.NOT_FOUND.name, "message": str(e)}, status=404)

@bp_errors.errorhandler(500)
def server_error(e):
    return send_json({"code": ErrorCodes.SERVER_ERROR.name, "message": str(e)}, status=500)

