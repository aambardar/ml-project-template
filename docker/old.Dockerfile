# Project old.Dockerfile with Micromamba
# Build: docker-compose build
# Run:   docker-compose up

# ==============================================================================
# Development image
# ==============================================================================
FROM mambaorg/micromamba:1.5-jammy AS development

# Set environment variables
ENV MAMBA_DOCKERFILE_ACTIVATE=1
ENV PATH="/opt/conda/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy environment file
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml .

# Install all dependencies (base + dev)
RUN micromamba install -y -n base -f environment.yml \
    && micromamba clean --all --yes

# Copy source code
COPY --chown=$MAMBA_USER:$MAMBA_USER src/ ./src/
COPY --chown=$MAMBA_USER:$MAMBA_USER tests/ ./tests/
COPY --chown=$MAMBA_USER:$MAMBA_USER pyproject.toml ./

# Install package in editable mode
RUN pip install -e . --no-deps

# Default command
CMD ["/bin/bash"]

# ==============================================================================
# Production image
# ==============================================================================
FROM mambaorg/micromamba:1.5-jammy AS production

ENV MAMBA_DOCKERFILE_ACTIVATE=1
ENV PATH="/opt/conda/bin:$PATH"

WORKDIR /app

# Copy environment file
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml .

# Install dependencies (could use a separate prod environment.yml without dev deps)
RUN micromamba install -y -n base -f environment.yml \
    && micromamba clean --all --yes

# Copy only production code
COPY --chown=$MAMBA_USER:$MAMBA_USER src/ ./src/
COPY --chown=$MAMBA_USER:$MAMBA_USER pyproject.toml ./

# Install package
RUN pip install . --no-deps

# Default command (override as needed)
CMD ["python", "-m", "src"]
