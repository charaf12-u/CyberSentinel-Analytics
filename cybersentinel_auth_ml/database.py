from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.engine import Connection, URL

from cybersentinel_auth_ml.config import (
    POSTGRES_CONNECT_TIMEOUT,
    POSTGRES_DB,
    POSTGRES_HOST,
    POSTGRES_PASSWORD,
    POSTGRES_PORT,
    POSTGRES_USER,
)


APPLICATION_NAME = "cybersentinel_auth_ml"


def build_database_url() -> URL:
    """
    Build a SQLAlchemy PostgreSQL URL from the ML configuration.

    URL.create safely handles special characters contained in the
    PostgreSQL username or password.
    """
    return URL.create(
        drivername="postgresql+psycopg2",
        username=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        database=POSTGRES_DB,
    )


def create_postgres_engine() -> Engine:
    """
    Create the PostgreSQL engine used by the authentication ML pipeline.
    """
    return create_engine(
        build_database_url(),
        pool_pre_ping=True,
        pool_recycle=1800,
        pool_timeout=30,
        connect_args={
            "connect_timeout": POSTGRES_CONNECT_TIMEOUT,
            "application_name": APPLICATION_NAME,
        },
    )


@contextmanager
def begin_connection(
    engine: Engine,
) -> Iterator[Connection]:
    """
    Open a transactional PostgreSQL connection.

    The transaction is committed when the context finishes successfully.
    It is automatically rolled back when an exception occurs.
    """
    with engine.begin() as connection:
        yield connection