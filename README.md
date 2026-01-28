# ML Project Template

A well-organized, reproducible starter template for machine learning projects in Python. Designed for teams using Docker and micromamba for consistent, reproducible development environments.

## Features

- **Micromamba** for fast, reproducible dependency management
- **Docker-first** development workflow
- Single `environment.yml` for all dependencies (Python + system libs)
- Pre-commit hooks for code quality
- Makefile for common commands
- Jupyter Lab integration
- GPU-ready (easy CUDA/cuDNN setup via conda-forge)

## Project Structure

```
ml-project-template/
├── data/
│   ├── raw/                  # Original, immutable data
│   ├── processed/            # Cleaned, transformed data
│   └── external/             # Third-party data sources
├── docker/
│   ├── base.Dockerfile       # Base ML image (team-wide)
│   └── Dockerfile            # Project image
├── models/                   # Trained and serialized models
├── notebooks/                # Jupyter notebooks for exploration and prototyping
├── outputs/
│   ├── figures/              # Generated graphics and plots
│   └── logs/                 # Training and experiment logs
├── src/
│   ├── data/                 # Data loading and preprocessing
│   ├── models/               # Model architectures
│   ├── training/             # Training scripts
│   └── utils/                # Helper functions
├── tests/                    # Unit and integration tests
├── configs/                  # Experiment and training configurations
├── environment.yml           # Dependencies (micromamba)
├── pyproject.toml            # Project metadata & tool configs
├── docker-compose.yml        # Docker configuration
├── Makefile                  # Common commands
├── .env.example              # Environment variables template
├── .pre-commit-config.yaml   # Code quality hooks
└── README.md
```

## New Developer Onboarding

Complete step-by-step guide for setting up this project on a new machine.

### Step 1: Install Prerequisites

Install the following on your machine (one-time setup):

**macOS:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install Make (usually pre-installed on macOS)
brew install make
```

**Ubuntu/Debian:**
```bash
# Install Docker
sudo apt-get update
sudo apt-get install docker.io docker-compose-v2 make

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

**Windows:**
1. Install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
2. Enable WSL2 backend in Docker Desktop settings
3. Install Make via [Chocolatey](https://chocolatey.org/): `choco install make`

**Verify installation:**
```bash
docker --version          # Should show Docker version
docker-compose --version  # Should show Docker Compose version
make --version            # Should show Make version
```

### Step 2: Clone the Repository

```bash
git clone <repository-url>
cd ml-project-template
```

### Step 3: Configure Environment

```bash
# Copy the environment template
cp .env.example .env

# Edit .env with your settings (API keys, paths, etc.)
```

### Step 4: Build the Docker Image

```bash
make build
```

This builds the development container with micromamba and all ML dependencies. First build takes longer as it downloads packages.

### Step 5: Start Development

```bash
# Start the container
make up

# Enter the container shell
make shell
```

You're now inside the container with:
- Python 3.11
- All ML packages (numpy, pandas, scikit-learn, jupyter, etc.)
- All dev tools (pytest, black, flake8, mypy)

### Step 6: Verify Setup

Run these commands inside the container to verify everything works:

```bash
# Check Python
python --version

# Check micromamba environment
micromamba list

# Check key packages
python -c "import numpy; import pandas; import sklearn; print('All packages OK')"

# Run tests
pytest tests/ -v

# Check linting
flake8 src/ --max-line-length=88
```

### Step 7: Start Coding

You're ready to contribute. Common workflows:

```bash
# Interactive development
make shell

# Start Jupyter Lab
make jupyter
# Open http://localhost:8888 in browser

# Run tests before committing
make test

# Format code before committing
make format
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `docker: command not found` | Install Docker Desktop and ensure it's running |
| `permission denied` on Linux | Run `sudo usermod -aG docker $USER` and logout/login |
| Port already in use | Stop other containers: `docker ps` then `docker stop <id>` |
| Build fails | Run `make clean` then `make build` |
| Container won't start | Check `.env` file exists: `cp .env.example .env` |

## Quick Start

For developers with prerequisites already installed:

```bash
git clone <repository-url>
cd ml-project-template
cp .env.example .env
make build
make up
make shell
```

## Available Commands

```bash
make help         # Show all commands

# Docker
make build        # Build Docker image
make up           # Start container (background)
make down         # Stop container
make shell        # Open shell in container

# Development
make jupyter      # Start Jupyter Lab (http://localhost:8888)
make train        # Run training script

# Code Quality
make lint         # Run flake8 + mypy
make format       # Run black + isort
make pre-commit   # Run all pre-commit hooks

# Testing
make test         # Run tests
make test-cov     # Run tests with coverage report

# Utilities
make clean        # Remove containers and cache
```

## Dependencies

Dependencies are managed in `environment.yml` using micromamba (conda-forge).

### File Responsibilities

| File | Purpose |
|------|---------|
| `environment.yml` | All dependencies (Python packages + system libs) |
| `pyproject.toml` | Project metadata + tool configurations (black, pytest, mypy) |

### Adding Dependencies

Edit `environment.yml`:

```yaml
dependencies:
  # Add conda packages
  - pytorch=2.1.2
  - cudatoolkit=11.8

  # Or add pip packages (if not on conda-forge)
  - pip:
      - transformers==4.37.0
```

Then rebuild:

```bash
make build
```

### Why Micromamba?

| Benefit | Description |
|---------|-------------|
| Fast installs | Parallel downloads, C++ implementation |
| Better resolver | SAT solver prevents dependency conflicts |
| System libraries | Installs CUDA, MKL, OpenCV without system packages |
| Reproducibility | Exact environment locks via `micromamba env export` |

## Docker

### Single Container Workflow

All development happens in one container:

```bash
make shell              # Interactive shell
make jupyter            # Jupyter Lab
make test               # Run tests
make lint               # Linting
```

Or run any command directly:

```bash
docker-compose run --rm dev python your_script.py
```

### Exposed Ports

| Port | Service |
|------|---------|
| 8888 | Jupyter Lab |
| 8000 | FastAPI/Uvicorn |
| 6006 | TensorBoard |
| 5000 | MLflow |

### Building Base Image (For Teams)

Build and share a base image to speed up builds:

```bash
docker build -f docker/base.Dockerfile -t your-registry/ml-base:1.0.0 .
docker push your-registry/ml-base:1.0.0
```

Update `docker/Dockerfile` to use it:

```dockerfile
FROM your-registry/ml-base:1.0.0
```

### GPU Support

To enable GPU support, add CUDA to `environment.yml`:

```yaml
dependencies:
  - pytorch=2.1.2
  - pytorch-cuda=11.8
  - cudatoolkit=11.8
```

And update `docker-compose.yml`:

```yaml
services:
  dev:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

## Environment Variables

```bash
cp .env.example .env
```

Key variables:
- `ENVIRONMENT` - development/staging/production
- `MLFLOW_TRACKING_URI` - MLflow server URL
- `WANDB_API_KEY` - Weights & Biases API key

## Code Quality

Pre-commit hooks enforce:

- **black** - Code formatting
- **isort** - Import sorting
- **flake8** - Linting
- **mypy** - Type checking
- **bandit** - Security checks

Run manually:

```bash
make pre-commit
```

## License

MIT License
