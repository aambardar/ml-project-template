.PHONY: help build up up-gpu down shell jupyter train lint format test test-cov pre-commit clean

# Run command in dev container (starts container if not running)
RUN = docker compose run --rm dev

# GPU compose files
COMPOSE_GPU = -f docker-compose.yml -f docker-compose.gpu.yml

# Default target
help:
	@echo "ML Project Template - Available Commands"
	@echo "========================================="
	@echo ""
	@echo "Getting Started:"
	@echo "  make build       - Build Docker image"
	@echo "  make up          - Start development container (CPU)"
	@echo "  make up-gpu      - Start development container (GPU)"
	@echo "  make down        - Stop container"
	@echo "  make shell       - Open shell in container"
	@echo ""
	@echo "Development:"
	@echo "  make jupyter     - Start Jupyter Lab (http://localhost:8888)"
	@echo "  make train       - Run training script"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint        - Run linters (flake8, mypy)"
	@echo "  make format      - Format code (black, isort)"
	@echo "  make pre-commit  - Run pre-commit hooks"
	@echo ""
	@echo "Testing:"
	@echo "  make test        - Run tests"
	@echo "  make test-cov    - Run tests with coverage"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean       - Remove containers and cache"

# ==============================================================================
# Docker
# ==============================================================================

build:
	docker compose build

up:
	docker compose up -d dev
	@echo ""
	@echo "Container started (CPU). Run 'make shell' to enter."

up-gpu:
	docker compose $(COMPOSE_GPU) up -d dev
	@echo ""
	@echo "Container started (GPU). Run 'make shell' to enter."

down:
	docker compose down

shell:
	@docker compose exec dev bash 2>/dev/null || docker compose run --rm dev bash

# ==============================================================================
# Remote VM Management
# ==============================================================================

vm-ssh:
	ssh $(DOCKER_VM_USER)@$(DOCKER_VM_IP)

vm-status:
	ssh $(DOCKER_VM_USER)@$(DOCKER_VM_IP) "docker ps"

vm-setup:
	@echo "Creating project directories on VM..."
	ssh $(DOCKER_VM_USER)@$(DOCKER_VM_IP) "mkdir -p $(DOCKER_VM_PROJECT_BASE_PATH) $(DOCKER_VM_DATA_BASE_PATH) $(DOCKER_VM_MODELS_BASE_PATH) $(DOCKER_VM_OUTPUTS_BASE_PATH)"
	@echo "Done. Directories created on VM."

# VM host: use 'mlvm' when at home, 'mlvm-tailscale' when away
VM_HOST ?= mlvm

sync-vm:
	@echo "Syncing project to VM ($(VM_HOST))..."
	rsync -avz --exclude '.git' --exclude '__pycache__' --exclude '.venv' \
		--exclude 'htmlcov' --exclude '.pytest_cache' --exclude '.mypy_cache' \
		--exclude '*.pyc' --exclude '.coverage' \
		. $(VM_HOST):~/projects/$(PROJECT_NAME)/
	@echo ""
	@echo "Project synced to VM at ~/projects/$(PROJECT_NAME)/"

# Sync via Tailscale (when away from home)
sync-vm-tailscale:
	$(MAKE) sync-vm VM_HOST=mlvm-tailscale

# ==============================================================================
# Development
# ==============================================================================

jupyter:
	$(RUN) jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root

train:
	$(RUN) python -m src.training.train

# ==============================================================================
# Code Quality
# ==============================================================================

lint:
	$(RUN) flake8 src/ tests/
	$(RUN) mypy src/

format:
	$(RUN) black src/ tests/
	$(RUN) isort src/ tests/

pre-commit:
	$(RUN) pre-commit run --all-files

# ==============================================================================
# Testing
# ==============================================================================

test:
	$(RUN) pytest tests/ -v

test-cov:
	$(RUN) pytest tests/ -v --cov=src --cov-report=html --cov-report=term-missing
	@echo ""
	@echo "Coverage report: htmlcov/index.html"

# ==============================================================================
# Utilities
# ==============================================================================

clean:
	docker compose down --rmi local --volumes --remove-orphans
	rm -rf __pycache__ .pytest_cache .mypy_cache .coverage htmlcov
	rm -rf build dist *.egg-info .ruff_cache
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
