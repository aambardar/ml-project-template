# Base ML Image with Micromamba
# Build and push to your registry for team-wide use:
#   docker build -f docker/base.Dockerfile -t your-registry/ml-base:1.0.0 .
#   docker push your-registry/ml-base:1.0.0

FROM mambaorg/micromamba:1.5-jammy

# Set environment variables
ENV MAMBA_DOCKERFILE_ACTIVATE=1
ENV PATH="/opt/conda/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy environment file
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml .

# Install dependencies
RUN micromamba install -y -n base -f environment.yml \
    && micromamba clean --all --yes

# Default command
CMD ["python"]
