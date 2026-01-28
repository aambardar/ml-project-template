# Base ML Image with GPU Support
# ================================
# This image provides a complete ML environment with:
# - CUDA runtime for GPU acceleration (via official PyTorch image)
# - PyTorch with CUDA support (works out of the box)
# - Core ML libraries (numpy, pandas, scikit-learn, etc.)
# - JupyterLab and development tools
#
# Build:
#   docker build -f docker/Dockerfile -t ml-base:latest .
#
# The image works both WITH and WITHOUT GPU:
# - With GPU: Full CUDA acceleration
# - Without GPU: Falls back to CPU automatically
#
# ==============================================================================
# Base image: Official PyTorch with CUDA support
# ==============================================================================
# 1. Use the version we discussed for RTX 2060 / CUDA 12.1 compatibility
FROM pytorch/pytorch:2.2.2-cuda12.1-cudnn8-runtime

# 2. Temporary Build-time variables (vanish after build)
ARG DEBIAN_FRONTEND=noninteractive

# 3. Persistent Environment Variables (stay in the container)
# We set these here because they are "static" logic for the app
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    APP_HOME=/app

WORKDIR $APP_HOME

# 4. System dependencies (using the noninteractive ARG from above)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 5. Install Python dependencies
# (Note: We use requirements.txt here for simplicity/speed in Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 6. Copy code last to keep build times fast
COPY . .

# 7. Metadata
LABEL maintainer="Ashu"
LABEL description="Stable ML environment with GPU support"

# Start the application
# Default command (can be overridden by docker-compose)
CMD ["python"]
