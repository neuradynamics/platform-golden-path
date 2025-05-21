# Base image
FROM python:3.11-slim AS base

# Builder stage
FROM base AS builder

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.7.3 /uv /bin/uv

# Set environment variables for builder
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    VIRTUAL_ENV=/.venv \
    PATH="/.venv/bin:${PATH}" \
    PYTHONPATH="/code:$PYTHONPATH"

# Set working directory
WORKDIR /code/app

# Copy only dependency files for better caching
COPY pyproject.toml ./

# Create the virtual environment explicitly
RUN /bin/uv venv ${VIRTUAL_ENV}

# Install dependencies with caching
RUN --mount=type=cache,target=/root/.cache/uv \
    /bin/uv pip install --no-cache-dir ".[dev]"

# Final stage - using the slim base image
FROM python:3.11-slim AS production

# Set environment variables
ENV VIRTUAL_ENV=/.venv \
    PATH="/.venv/bin:${PATH}" \
    PYTHONPATH="/code" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /code/app

# Copy virtual environment from builder
COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# Copy application code
COPY . .

# Make entrypoint script executable
RUN chmod +x /code/app/entrypoint.sh

# Expose port
EXPOSE 8000

# Use entrypoint script
ENTRYPOINT ["/code/app/entrypoint.sh"]