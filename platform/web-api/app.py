from flask import Flask
from flask_cors import CORS

from common import wsgi
from common.middleware import api_middleware

from common.error import bp_errors
from handlers.iam import bp_iam


app = Flask(__name__)

CORS(app, origins=["*"], methods=["*"])

app.config.from_mapping(SECRET_KEY="oGKbZXxDLhlxy3aQ7ASEmV6s8tjKmJpv")

app.register_blueprint(bp_errors)
app.register_blueprint(bp_iam)


@api_middleware
def request_handler(event, context):
    return wsgi.response(app, event, context)


if __name__ == '__main__':
    app.run(debug=True)

