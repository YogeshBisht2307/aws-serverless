from common.base import Logger
from common.base import send_success_code
from common.middleware import webuser_required


from flask import Blueprint

logger = Logger("IAMController")
bp_iam = Blueprint('iam', __name__, url_prefix='/iam')


@bp_iam.route('/users', methods=["GET"])
@webuser_required
def get_iam_users(auth: dict):
    return send_success_code()


