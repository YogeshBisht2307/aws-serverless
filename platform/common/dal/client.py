import os
import json
import psycopg2

from common.services import secret
from common.base import Logger
from common.constants import SecretsNameEnum


logger = Logger("DatabaseClientService")


def get_credentials() -> dict:
    if os.environ.get('STAGE') == 'dev':
        return { SecretsNameEnum.APP_DB_CREDS.value: os.environ["DB_CREDS"] }

    status, secrets =  secret.get_secrets([SecretsNameEnum.APP_DB_CREDS.value])
    if not status:
        return {}

    return secrets


class PostgresqlClient:
    """PostgreSQL Database class."""

    def __init__(self):
        credentials = get_credentials()
        psql_creds = json.loads(credentials[SecretsNameEnum.APP_DB_CREDS.value])
        self.host = psql_creds['ip']
        self.username = psql_creds['username']
        self.password = psql_creds['password']
        self.port = psql_creds['port']
        self.dbname = psql_creds['dbName']
        self.conn = None

    def connect(self):
        """Connect to a Postgres database."""
        if self.conn is None:
            try:
                self.conn = psycopg2.connect(
                    host=self.host,
                    user=self.username,
                    password=self.password,
                    port=self.port,
                    database=self.dbname
                )
                self.conn.set_session(autocommit=True)
            except psycopg2.DatabaseError as error:
                logger.error(error)
                raise error
            finally:
                logger.info('Connection opened successfully.')

    def get_db(self):
        if self.conn:
            return self.conn

        self.connect()
        return self.conn

psql_client = PostgresqlClient()