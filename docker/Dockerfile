# Project Dockerfile
# For development: docker-compose up
# For production:  docker build -f docker/Dockerfile -t ml-project:latest .

# ==============================================================================
# Stage 1: Base with dependencies
# ==============================================================================
FROM python:3.11-slim AS dependencies

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy dependency specification
COPY pyproject.toml .

# Install dependencies (base + project-specific)
RUN pip install --upgrade pip setuptools wheel \
    && pip install ".[base]"

# ==============================================================================
# Stage 2: Development image
# ==============================================================================
FROM dependencies AS development

# Install dev dependencies
RUN pip install ".[base,dev]"

# Copy source code
COPY src/ ./src/
COPY tests/ ./tests/

# Install package in editable mode
RUN pip install -e .

# Default command for development
CMD ["python"]

# ==============================================================================
# Stage 3: Production image
# ==============================================================================
FROM dependencies AS production

# Copy only what's needed for production
COPY src/ ./src/
COPY pyproject.toml .

# Install package
RUN pip install .

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash appuser \
    && chown -R appuser:appuser /app
USER appuser

# Default command (override as needed)
CMD ["python", "-m", "src"]
