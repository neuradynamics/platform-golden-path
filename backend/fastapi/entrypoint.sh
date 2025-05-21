#!/bin/bash
set -e

# Run migrations
alembic upgrade head

# The command will be provided by docker-compose
exec "$@"