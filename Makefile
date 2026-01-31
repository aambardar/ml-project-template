# ==============================================================================
# ML Project Template - Makefile
# ==============================================================================

.PHONY: help \
        build up up-gpu down shell \
        build-dev up-dev up-gpu-dev \
        build-test up-test up-gpu-test \
        build-prod up-prod up-gpu-prod \
        jupyter train \
        lint format pre-commit \
        test test-cov \
        vm-ssh vm-status vm-setup sync-vm sync-vm-tailscale \
        clean

# ==============================================================================
# VARIABLES
# ==============================================================================

# Environment files
ENV_FILE ?= .env.dev
TEST_ENV_FILE ?= .env.test
PROD_ENV_FILE ?= .env.prod

# Compose files
COMPOSE_BASE := docker-compose.yml
COMPOSE_GPU := docker-compose.gpu.yml
COMPOSE_DEV := docker-compose.dev.yml
COMPOSE_TEST := docker-compose.test.yml
COMPOSE_PROD := docker-compose.prod.yml

# VM host: use 'mlvm' when at home, 'mlvm-tailscale' when away
VM_HOST ?= mlvm

# Service name (functional name, same across all environments)
SERVICE_NAME := oneringtorulethemall

# Run command in container
RUN = docker compose --env-file $(ENV_FILE) run --rm $(SERVICE_NAME)

# Shell settings
.ONESHELL:
SHELL := /bin/bash

# ==============================================================================
# HELP
# ==============================================================================

help:
	@echo "ML Project Template - Available Commands"
	@echo "========================================="
	@echo ""
	@echo "Docker (Base):"
	@echo "  make build         - Build Docker image"
	@echo "  make up            - Start container (CPU)"
	@echo "  make up-gpu        - Start container (GPU)"
	@echo "  make down          - Stop container"
	@echo "  make shell         - Open shell in container"
	@echo ""
	@echo "Docker (Development):"
	@echo "  make build-dev     - Build with dev overrides"
	@echo "  make up-dev        - Start dev container (CPU)"
	@echo "  make up-gpu-dev    - Start dev container (GPU)"
	@echo ""
	@echo "Docker (Test):"
	@echo "  make build-test    - Build with test overrides"
	@echo "  make up-test       - Start test container (CPU)"
	@echo "  make up-gpu-test   - Start test container (GPU)"
	@echo ""
	@echo "Docker (Production):"
	@echo "  make build-prod    - Build with prod overrides"
	@echo "  make up-prod       - Start prod container (CPU)"
	@echo "  make up-gpu-prod   - Start prod container (GPU)"
	@echo ""
	@echo "Development:"
	@echo "  make jupyter       - Start Jupyter Lab"
	@echo "  make train         - Run training script"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint          - Run linters (flake8, mypy)"
	@echo "  make format        - Format code (black, isort)"
	@echo "  make pre-commit    - Run pre-commit hooks"
	@echo ""
	@echo "Testing:"
	@echo "  make test          - Run tests"
	@echo "  make test-cov      - Run tests with coverage"
	@echo ""
	@echo "Remote VM:"
	@echo "  make vm-ssh        - SSH into VM"
	@echo "  make vm-status     - Check Docker status on VM"
	@echo "  make vm-setup      - Create project directories on VM"
	@echo "  make sync-vm       - Rsync project to VM"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean         - Remove containers and cache"

# ==============================================================================
# Docker - Base
# ==============================================================================

build:
	docker compose -f $(COMPOSE_BASE) --env-file $(ENV_FILE) build

up:
	docker compose -f $(COMPOSE_BASE) --env-file $(ENV_FILE) up -d
	@echo ""
	@echo "Container started (CPU). Run 'make shell' to enter."

up-gpu:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_GPU) --env-file $(ENV_FILE) up -d
	@echo ""
	@echo "Container started (GPU). Run 'make shell' to enter."

down:
	docker compose --env-file $(ENV_FILE) down

shell:
	@docker compose --env-file $(ENV_FILE) exec $(SERVICE_NAME) bash 2>/dev/null || \
		docker compose --env-file $(ENV_FILE) run --rm $(SERVICE_NAME) bash

# ==============================================================================
# Docker - Development Environment
# ==============================================================================

build-dev:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_DEV) --env-file $(ENV_FILE) build

up-dev:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_DEV) --env-file $(ENV_FILE) up -d
	@echo ""
	@echo "DEV container started (CPU). Run 'make shell' to enter."

up-gpu-dev:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_DEV) -f $(COMPOSE_GPU) --env-file $(ENV_FILE) up -d
	@echo ""
	@echo "DEV container started (GPU). Run 'make shell' to enter."

# ==============================================================================
# Docker - Test Environment
# ==============================================================================

build-test:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_TEST) --env-file $(TEST_ENV_FILE) build

up-test:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_TEST) --env-file $(TEST_ENV_FILE) up -d
	@echo ""
	@echo "TEST container started (CPU). Run 'make shell' to enter."

up-gpu-test:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_TEST) -f $(COMPOSE_GPU) --env-file $(TEST_ENV_FILE) up -d
	@echo ""
	@echo "TEST container started (GPU). Run 'make shell' to enter."

# ==============================================================================
# Docker - Production Environment
# ==============================================================================

build-prod:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_PROD) --env-file $(PROD_ENV_FILE) build

up-prod:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_PROD) --env-file $(PROD_ENV_FILE) up -d
	@echo ""
	@echo "PROD container started (CPU). Run 'make shell' to enter."

up-gpu-prod:
	docker compose -f $(COMPOSE_BASE) -f $(COMPOSE_PROD) -f $(COMPOSE_GPU) --env-file $(PROD_ENV_FILE) up -d
	@echo ""
	@echo "PROD container started (GPU). Run 'make shell' to enter."

# ==============================================================================
# Remote VM Management
# ==============================================================================

vm-ssh:
	ssh $(VM_HOST)

vm-status:
	ssh $(VM_HOST) "docker ps"

vm-setup:
	@echo "Creating project directories on VM..."
	ssh $(VM_HOST) "mkdir -p ~/workspace/projects ~/workspace/data ~/workspace/models ~/workspace/outputs"
	@echo "Done. Directories created on VM."

sync-vm:
	@echo "Syncing project to VM ($(VM_HOST))..."
	rsync -avz --exclude '.git' --exclude '__pycache__' --exclude '.venv' \
		--exclude 'htmlcov' --exclude '.pytest_cache' --exclude '.mypy_cache' \
		--exclude '*.pyc' --exclude '.coverage' --exclude 'data/' \
		--exclude 'models/' --exclude 'outputs/' \
		. $(VM_HOST):~/workspace/projects/$$(basename $$(pwd))/
	@echo ""
	@echo "Project synced to VM."

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
	docker compose --env-file $(ENV_FILE) down --rmi local --volumes --remove-orphans 2>/dev/null || true
	rm -rf __pycache__ .pytest_cache .mypy_cache .coverage htmlcov
	rm -rf build dist *.egg-info .ruff_cache
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "Cleaned up containers, images, and cache files."
