import json
import logging

from flask import Blueprint
from flask import Response


bp_iam = Blueprint('contents', __name__, url_prefix='/iam')


@bp_iam.route('/users', methods=["GET"])
def get_iam_users():
    return Response(json.dumps({"status": "SUCCESS"}), status=200)

