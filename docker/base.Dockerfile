# Base ML Image
# Build and push to your registry for team-wide use:
#   docker build -f docker/base.Dockerfile -t your-registry/ml-base:1.0.0 .
#   docker push your-registry/ml-base:1.0.0

FROM python:3.11-slim AS base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Set working directory
WORKDIR /app

# Install system dependencies
# Layer 1: System packages (rarely changes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Layer 2: Base ML dependencies (changes occasionally)
# Copy only pyproject.toml first for better caching
COPY pyproject.toml .

# Install base ML packages
RUN pip install --upgrade pip setuptools wheel \
    && pip install ".[base]"

# Default command
CMD ["python"]
