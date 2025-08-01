"""
Global pytest configuration and fixtures.
"""

import asyncio
import logging
import os
import re
from contextlib import asynccontextmanager
from typing import AsyncGenerator, Callable

import pytest
import pytest_asyncio
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.config.db import Base, get_async_session
from app.main import app

logger = logging.getLogger(__name__)

# Database configuration for tests
db_user = os.getenv("POSTGRES_USER", "postgres")
db_password = os.getenv("POSTGRES_PASSWORD", "password")
db_host = os.getenv("POSTGRES_HOST", "postgres_db")
db_name = os.getenv("POSTGRES_DB", "postgres")

default_admin_db_url = (
    f"postgresql+asyncpg://{db_user}:{db_password}@{db_host}:5432/{db_name}"
)

ADMIN_DB_CONNECTION_URL = os.getenv("TEST_DATABASE_URL", default_admin_db_url)

TEST_DB_NAME_PREFIX = "test_db_"


@pytest.fixture(scope="session")
def app_fixture():
    """Fixture that provides the FastAPI app instance."""
    return app


@pytest.fixture(scope="session")
def test_client(app_fixture):
    """Provides a TestClient instance for the FastAPI app."""
    return TestClient(app_fixture)


@pytest_asyncio.fixture(scope="session")
def event_loop():
    """Provides an event loop for the test session."""
    policy = asyncio.get_event_loop_policy()
    loop = policy.new_event_loop()
    asyncio.set_event_loop(loop)
    yield loop
    loop.close()


@asynccontextmanager
async def _create_test_database(
    db_name_to_create: str,
    admin_connection_url_for_ops: str,
    worker_specific_db_url: str,
):
    """
    Creates and manages the lifecycle of a worker-specific test database.
    """
    admin_engine = create_async_engine(
        admin_connection_url_for_ops, isolation_level="AUTOCOMMIT"
    )

    try:
        async with admin_engine.connect() as conn:
            logger.info(
                "Attempting to drop database %s if it exists.", db_name_to_create
            )
            await conn.execute(
                text(
                    f"""
                    SELECT pg_terminate_backend(pg_stat_activity.pid)
                    FROM pg_stat_activity
                    WHERE pg_stat_activity.datname = '{db_name_to_create}'
                    AND pg_stat_activity.pid <> pg_backend_pid();
                """
                )
            )
            await asyncio.sleep(0.5)
            await conn.execute(text(f"DROP DATABASE IF EXISTS {db_name_to_create}"))
            logger.info("Creating database %s.", db_name_to_create)
            await conn.execute(text(f"CREATE DATABASE {db_name_to_create}"))

        engine = create_async_engine(
            worker_specific_db_url,
            echo=False,
            pool_pre_ping=True,
            connect_args={"timeout": 30},
        )
        async with engine.begin() as conn:
            logger.info("Creating all tables in database %s.", db_name_to_create)
            await conn.run_sync(Base.metadata.create_all)
        await engine.dispose()

        yield worker_specific_db_url

    finally:
        logger.info("Cleaning up database %s.", db_name_to_create)
        try:
            async with admin_engine.connect() as conn:
                logger.info(
                    "Terminating any active connections to database %s for cleanup.",
                    db_name_to_create,
                )
                await conn.execute(
                    text(
                        f"""
                        SELECT pg_terminate_backend(pg_stat_activity.pid)
                        FROM pg_stat_activity
                        WHERE pg_stat_activity.datname = '{db_name_to_create}'
                        AND pg_stat_activity.pid <> pg_backend_pid();
                        """
                    )
                )
                await asyncio.sleep(1)  # Allow time for connections to terminate

                logger.info("Attempting to drop database %s.", db_name_to_create)
                await conn.execute(text(f"DROP DATABASE IF EXISTS {db_name_to_create}"))
                logger.info("Database %s dropped successfully.", db_name_to_create)
        except Exception as e:
            logger.error(
                "Error during database cleanup operations for %s: %s. "
                "The database might still exist.",
                db_name_to_create,
                e,
            )
        finally:
            await admin_engine.dispose()


@pytest_asyncio.fixture(scope="session")
async def setup_database(worker_id: str) -> AsyncGenerator[str, None]:
    """
    Sets up a unique, isolated database for each worker session.
    Yields the connection URL to this worker-specific database.
    """
    admin_url_for_ops = ADMIN_DB_CONNECTION_URL

    if not admin_url_for_ops:
        raise ValueError(
            """TEST_DATABASE_URL environment variable is not set or empty.
            It's required for admin operations."""
        )

    try:
        admin_url_parts = admin_url_for_ops.split("/")
        db_server_base_url = "/".join(admin_url_parts[:-1])
    except Exception as e:
        raise ValueError(
            f"Could not parse database server base URL from ADMIN_DB_CONNECTION_URL ('{admin_url_for_ops}'): {e}",
        ) from e

    if worker_id == "master":
        db_name_to_create = f"{TEST_DB_NAME_PREFIX}master"
    else:
        # Ensure worker_id is filesystem/DB name friendly if it contains special chars
        safe_worker_id = re.sub(r"\\W+", "_", worker_id)
        db_name_to_create = f"{TEST_DB_NAME_PREFIX}{safe_worker_id}"

    worker_specific_db_url = f"{db_server_base_url}/{db_name_to_create}"

    async with _create_test_database(
        db_name_to_create, admin_url_for_ops, worker_specific_db_url
    ) as final_worker_db_url:
        yield final_worker_db_url


@pytest_asyncio.fixture
async def db_session(setup_database: str) -> AsyncGenerator[AsyncSession, None]:
    """Provides a database session for tests with automatic rollback."""
    worker_db_url = setup_database
    engine = create_async_engine(
        worker_db_url,
        echo=False,
        pool_recycle=3600,
        pool_pre_ping=True,
    )
    TestingSessionLocal = sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=True,
    )

    async with TestingSessionLocal() as session:
        await session.begin()
        try:
            yield session
        finally:
            try:
                if session.in_transaction():
                    await session.rollback()
            except Exception:
                if session.in_transaction():
                    await session.rollback()
            finally:
                await session.close()
    await engine.dispose()


@pytest_asyncio.fixture
async def get_test_async_session(db_session, event_loop):
    """Provides a session factory for dependency injection."""
    asyncio.set_event_loop(event_loop)

    async def _get_test_session():
        try:
            yield db_session
        finally:
            pass

    return _get_test_session


@pytest_asyncio.fixture(autouse=True)
async def override_db_dependency(app_fixture, get_test_async_session):
    """Automatically overrides the database dependency for all tests."""
    app_fixture.dependency_overrides[get_async_session] = get_test_async_session
    yield
    if get_async_session in app_fixture.dependency_overrides:
        del app_fixture.dependency_overrides[get_async_session]


@pytest.fixture
def override_dependencies(app_fixture):
    """Fixture for overriding FastAPI dependencies in tests."""
    original_overrides = app_fixture.dependency_overrides.copy()
    temp_overrides = {}

    def _override_dependency(dependency: Callable, override_with: Callable) -> None:
        """
        Override a dependency with a test double or mock.

        Args:
            dependency: The dependency to override
            override_with: The replacement dependency
        """
        temp_overrides[dependency] = override_with
        app_fixture.dependency_overrides[dependency] = override_with

    yield _override_dependency
    app_fixture.dependency_overrides = original_overrides
