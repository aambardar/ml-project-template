# ML Project Template

A production-ready machine learning project template designed for **remote Docker development**. Code locally on your MacBook using PyCharm Pro while executing in a consistent Docker environment hosted on a remote VM with GPU support.

## Key Features

- **Remote Docker Development** — Docker runs on a VM; code locally on any MacBook
- **PyCharm Pro Integration** — Full IDE support with remote interpreters
- **GPU Ready** — CUDA 12.1 + cuDNN 8 via official PyTorch image
- **Multi-Developer Support** — Multiple developers share the same ML environment
- **Separated Concerns** — Code synced via IDE; data/models/outputs stay on VM
- **Pre-commit Hooks** — Enforced code quality (black, isort, flake8, mypy, bandit)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HOME NETWORK                                    │
│                                                                              │
│  ┌────────────────────┐         ┌────────────────────────────────────────┐  │
│  │  Developer MacBook │         │  VM Host (e.g., 192.168.1.39)          │  │
│  │                    │         │                                        │  │
│  │  ┌──────────────┐  │  SSH +  │  ~/workspace/                          │  │
│  │  │ PyCharm Pro  │──┼─────────┼──► projects/<project>/  (code)        │  │
│  │  │              │  │  Sync   │      ▲                                 │  │
│  │  │ Local Code   │  │         │      │ mounted at /app                │  │
│  │  └──────────────┘  │         │      │                                 │  │
│  │                    │         │  ┌───┴────────────────────────────┐   │  │
│  │  Git clone here    │         │  │     Docker Container (ml-dev)  │   │  │
│  │                    │         │  │     - Python 3.11              │   │  │
│  └────────────────────┘         │  │     - PyTorch + CUDA           │   │  │
│                                 │  │     - All ML libraries         │   │  │
│  ┌────────────────────┐         │  │                                │   │  │
│  │  Developer MacBook │         │  │  /data    ← datasets           │   │  │
│  │  (Second Dev)      │─────────┼──│  /models  ← trained models     │   │  │
│  │                    │         │  │  /outputs ← logs, figures      │   │  │
│  └────────────────────┘         │  └────────────────────────────────┘   │  │
│                                 │                                        │  │
└─────────────────────────────────┴────────────────────────────────────────┘
```

## Project Structure

```
ml-project-template/
├── docker/
│   └── Dockerfile            # ML environment (PyTorch + CUDA base)
├── src/
│   ├── data/                 # Data loading and preprocessing
│   ├── models/               # Model architectures
│   ├── training/             # Training scripts
│   └── utils/                # Helper functions
├── configs/                  # Experiment configurations (YAML)
├── notebooks/                # Jupyter notebooks for exploration
├── tests/                    # Unit and integration tests
├── docs/                     # Documentation
├── data/                     # [Local placeholder - actual data on VM]
├── models/                   # [Local placeholder - actual models on VM]
├── outputs/                  # [Local placeholder - actual outputs on VM]
├── docker-compose.yml        # Base Docker configuration
├── docker-compose.gpu.yml    # GPU override (adds NVIDIA runtime)
├── requirements.txt          # Python dependencies
├── Makefile                  # Common commands
├── .env.example              # Environment variables template
├── .pre-commit-config.yaml   # Code quality hooks
└── README.md
```

---

# Setup Guide

## Part 1: VM Host Setup (One-Time)

These steps are performed **once** on the VM that will host Docker.

### 1.1 Verify Docker Installation

SSH into your VM and verify Docker is installed and running:

```bash
ssh your-user@192.168.1.39

# Check Docker is installed
docker --version
# Expected: Docker version 24.x or higher

# Check Docker daemon is running
sudo systemctl status docker
# Expected: Active: active (running)

# Verify your user can run Docker without sudo
docker ps
# Should work without permission errors

# If permission denied, add user to docker group:
sudo usermod -aG docker $USER
# Then logout and login again
```

### 1.2 Verify NVIDIA Container Toolkit (For GPU Support)

```bash
# Check NVIDIA driver
nvidia-smi
# Should show GPU info and driver version

# Check NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
# Should show GPU info inside container
```

If NVIDIA Container Toolkit is not installed:
```bash
# Add NVIDIA repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 1.3 Create Workspace Directories

```bash
# Create the workspace structure on VM
mkdir -p ~/workspace/projects
mkdir -p ~/workspace/data
mkdir -p ~/workspace/models
mkdir -p ~/workspace/outputs

# Verify
ls -la ~/workspace/
# Should show: projects/  data/  models/  outputs/
```

### 1.4 Clone and Build the Docker Image

```bash
# Clone the template (or your project)
cd ~/workspace/projects
git clone https://github.com/your-org/ml-project-template.git
cd ml-project-template

# Copy and configure environment
cp .env.dev.example .env.dev
nano .env.dev  # Edit with your settings

# Build the Docker image
docker compose build

# Verify image was created
docker images | grep ml-base
# Should show: ml-base:latest
```

### 1.5 Start the Container

```bash
# CPU mode
docker compose up -d

# OR GPU mode
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d

# Verify container is running
docker ps
# Should show: ml-dev container running

# Test GPU access (if using GPU mode)
docker exec ml-dev python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

---

## Part 2: Docker Image & Container Setup

### 2.1 If Container Doesn't Exist

On the VM, navigate to the project and start the container:

```bash
cd ~/workspace/projects/ml-project-template

# Build image (if not built)
docker compose build

# Start container (CPU)
docker compose up -d

# OR Start container (GPU)
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

### 2.2 If Container Exists But Stopped

```bash
# Check container status
docker ps -a | grep ml-dev

# Start existing container
docker compose up -d

# OR with GPU
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

### 2.3 Rebuild After Dockerfile Changes

```bash
# Rebuild and restart
docker compose down
docker compose build --no-cache
docker compose up -d
```

### 2.4 Verify Container Health

```bash
# Check container is running
docker ps

# Check container logs
docker logs ml-dev

# Enter container shell
docker exec -it ml-dev bash

# Inside container, verify environment
python --version
python -c "import torch; import pandas; import sklearn; print('All packages OK')"
```

---

## Part 3: Developer Workstation Setup (PyCharm Pro)

These steps are performed on **each developer's MacBook**.

### 3.1 Prerequisites

- **PyCharm Professional** (Community edition doesn't support remote interpreters)
- **SSH key** configured for passwordless access to VM
- **Git** installed

### 3.2 Clone Repository Locally

```bash
# On your MacBook
cd ~/Projects
git clone https://github.com/your-org/ml-project-template.git
cd ml-project-template

# Copy environment template
cp .env.dev.example .env.dev
# Edit .env.dev with your settings (especially VM IP and paths)
```

### 3.3 Configure SSH Access

Ensure you can SSH to the VM without password:

```bash
# Test SSH connection
ssh your-user@192.168.1.39

# If prompted for password, set up SSH key:
ssh-keygen -t ed25519  # Generate key (if you don't have one)
ssh-copy-id your-user@192.168.1.39  # Copy to VM

# Add to SSH config for convenience (~/.ssh/config)
Host mlvm
    HostName 192.168.1.39
    User your-user
    IdentityFile ~/.ssh/id_ed25519
```

### 3.4 Configure PyCharm Deployment (File Sync)

This sets up automatic file synchronization from your MacBook to the VM.

1. **Open PyCharm** → Open your cloned project

2. **Tools → Deployment → Configuration**

3. **Click '+' → SFTP**
   - Name: `ML-VM`
   - Host: `192.168.1.39`
   - Port: `22`
   - Username: `your-user`
   - Authentication: Key pair
   - Private key: `~/.ssh/id_ed25519`
   - Click "Test Connection" to verify

4. **Mappings tab**
   - Local path: `/Users/you/Projects/ml-project-template`
   - Deployment path: `/home/your-user/workspace/projects/ml-project-template`

5. **Excluded Paths tab** — Add these to avoid syncing large files:
   - `data`
   - `models`
   - `outputs`
   - `.git`
   - `__pycache__`
   - `.pytest_cache`
   - `htmlcov`

6. **Tools → Deployment → Options**
   - Check "Upload changed files automatically to the default server"
   - Select "On explicit save action (Ctrl+S)"

### 3.5 Configure PyCharm Remote Docker Interpreter

This tells PyCharm to use the Python interpreter inside the Docker container on the VM.

1. **PyCharm → Settings → Build, Execution, Deployment → Docker**

2. **Click '+' → Docker**
   - Name: `ML-VM-Docker`
   - Connect via: SSH
   - Host: `192.168.1.39`
   - Username: `your-user`
   - Auth: Key pair
   - Click "Test Connection"

3. **Settings → Project → Python Interpreter**

4. **Click gear icon → Add → On Docker Compose**
   - Server: `ML-VM-Docker` (the one you just created)
   - Configuration files: Select `docker-compose.yml`
   - Service: `dev`
   - Python interpreter path: `python`

5. **Apply** — PyCharm will now index packages from the remote container

### 3.6 Verify Setup

1. Create a test file `test_setup.py`:
   ```python
   import torch
   import pandas as pd
   print(f"PyTorch version: {torch.__version__}")
   print(f"CUDA available: {torch.cuda.is_available()}")
   print(f"Pandas version: {pd.__version__}")
   ```

2. **Right-click → Run** — Should execute on remote Docker container

3. Check that file was synced to VM:
   ```bash
   ssh mlvm "ls ~/workspace/projects/ml-project-template/test_setup.py"
   ```

---

## Part 4: File Sync and Mount Points

### How Synchronization Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FILE SYNCHRONIZATION FLOW                            │
│                                                                              │
│   MacBook (Local)                    VM (Remote)                             │
│   ───────────────                    ──────────                              │
│                                                                              │
│   ~/Projects/ml-project/             ~/workspace/projects/ml-project/        │
│   ├── src/  ─────────────────────►   ├── src/                               │
│   ├── configs/ ──────────────────►   ├── configs/                           │
│   ├── notebooks/ ────────────────►   ├── notebooks/                         │
│   ├── tests/ ────────────────────►   ├── tests/                             │
│   │                                  │                                       │
│   │   PyCharm Deployment             │       Docker Volume Mount             │
│   │   (SFTP on save)                 │       (-v path:/app)                  │
│   │                                  │              │                        │
│   │                                  │              ▼                        │
│   │                                  │   ┌─────────────────────┐            │
│   │                                  │   │  Docker Container   │            │
│   │                                  │   │                     │            │
│   │                                  │   │  /app ◄─────────────┤            │
│   ├── data/ (NOT synced)             │   │  /data ◄────────────┼── ~/workspace/data/ml-project/
│   ├── models/ (NOT synced)           │   │  /models ◄──────────┼── ~/workspace/models/ml-project/
│   └── outputs/ (NOT synced)          │   │  /outputs ◄─────────┼── ~/workspace/outputs/ml-project/
│                                      │   └─────────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Mount Points Explained

| Container Path | VM Host Path | Purpose | Synced from MacBook? |
|----------------|--------------|---------|----------------------|
| `/app` | `~/workspace/projects/<project>/` | Source code | ✅ Yes (via PyCharm) |
| `/data` | `~/workspace/data/<project>/` | Datasets | ❌ No (too large) |
| `/models` | `~/workspace/models/<project>/` | Trained models | ❌ No (too large) |
| `/outputs` | `~/workspace/outputs/<project>/` | Logs, figures | ❌ No |

### Why This Separation?

1. **Code (`/app`)** — Small files, frequently edited, synced via PyCharm
2. **Data (`/data`)** — Large files (GBs), rarely change, stay on VM
3. **Models (`/models`)** — Large files, generated by training, stay on VM
4. **Outputs (`/outputs`)** — Generated files, logs, stay on VM

### Using Paths in Python Code

```python
from pathlib import Path

# These paths are INSIDE the container
DATA_DIR = Path("/data")
MODELS_DIR = Path("/models")
OUTPUTS_DIR = Path("/outputs")

# Example usage
train_data = DATA_DIR / "raw" / "train.csv"
model_path = MODELS_DIR / "experiment_1" / "best_model.pt"
figure_path = OUTPUTS_DIR / "figures" / "loss_curve.png"
```

---

## Part 5: Available Commands

### Makefile Commands

```bash
make help         # Show all available commands

# Docker
make build        # Build Docker image
make up           # Start container (CPU)
make up-gpu       # Start container (GPU)
make down         # Stop container
make shell        # Open shell in container

# Development
make jupyter      # Start Jupyter Lab
make train        # Run training script

# Code Quality
make lint         # Run flake8 + mypy
make format       # Run black + isort
make pre-commit   # Run all pre-commit hooks

# Testing
make test         # Run tests
make test-cov     # Run tests with coverage

# VM Management
make vm-ssh       # SSH into VM
make vm-status    # Check Docker status on VM
make sync-vm      # Rsync project to VM
```

### Exposed Ports

| Port | Service | Access URL |
|------|---------|------------|
| 8888 | JupyterLab | `http://192.168.1.39:8888` |
| 8000 | FastAPI / Model Serving | `http://192.168.1.39:8000` |
| 6006 | TensorBoard | `http://192.168.1.39:6006` |
| 5000 | MLflow | `http://192.168.1.39:5000` |

---

## Part 6: Code Quality

Pre-commit hooks automatically run on `git commit`:

| Tool | Purpose |
|------|---------|
| **black** | Code formatting |
| **isort** | Import sorting |
| **flake8** | Linting + style checks |
| **mypy** | Type checking |
| **bandit** | Security scanning |
| **nbstripout** | Clean notebook outputs |

### Manual Execution

```bash
# Run all hooks
make pre-commit

# Format code
make format

# Lint code
make lint
```

---

## Example Scenario: Two Projects, Two Developers

This example demonstrates two developers (Alice and Bob) working on two separate projects (ProjectOne and ProjectTwo) using the same VM infrastructure.

### VM Setup (Shared Infrastructure)

```
VM Host: 192.168.1.39
User: mluser

Directory Structure:
~/workspace/
├── projects/
│   ├── ProjectOne/        # Alice's project code
│   └── ProjectTwo/        # Bob's project code
├── data/
│   ├── ProjectOne/        # Alice's datasets
│   └── ProjectTwo/        # Bob's datasets
├── models/
│   ├── ProjectOne/        # Alice's trained models
│   └── ProjectTwo/        # Bob's trained models
└── outputs/
    ├── ProjectOne/        # Alice's outputs
    └── ProjectTwo/        # Bob's outputs
```

### Alice's Setup (ProjectOne)

**On Alice's MacBook:**

1. Clone and configure:
   ```bash
   cd ~/Projects
   git clone https://github.com/company/ProjectOne.git
   cd ProjectOne
   cp .env.dev.example .env.dev
   ```

2. Edit `.env`:
   ```bash
   PROJECT_NAME=ProjectOne
   DOCKER_VM_IP=192.168.1.39
   DOCKER_VM_USER=mluser
   DOCKER_VM_PROJECT_BASE_PATH=/home/mluser/workspace/projects
   DOCKER_VM_DATA_BASE_PATH=/home/mluser/workspace/data
   DOCKER_VM_MODELS_BASE_PATH=/home/mluser/workspace/models
   DOCKER_VM_OUTPUTS_BASE_PATH=/home/mluser/workspace/outputs
   ```

3. PyCharm Deployment mapping:
   - Local: `/Users/alice/Projects/ProjectOne`
   - Remote: `/home/mluser/workspace/projects/ProjectOne`

4. Container name: `projectone-dev` (or shared `ml-dev`)

### Bob's Setup (ProjectTwo)

**On Bob's MacBook:**

1. Clone and configure:
   ```bash
   cd ~/Projects
   git clone https://github.com/company/ProjectTwo.git
   cd ProjectTwo
   cp .env.dev.example .env.dev
   ```

2. Edit `.env`:
   ```bash
   PROJECT_NAME=ProjectTwo
   DOCKER_VM_IP=192.168.1.39
   DOCKER_VM_USER=mluser
   DOCKER_VM_PROJECT_BASE_PATH=/home/mluser/workspace/projects
   DOCKER_VM_DATA_BASE_PATH=/home/mluser/workspace/data
   DOCKER_VM_MODELS_BASE_PATH=/home/mluser/workspace/models
   DOCKER_VM_OUTPUTS_BASE_PATH=/home/mluser/workspace/outputs
   ```

3. PyCharm Deployment mapping:
   - Local: `/Users/bob/Projects/ProjectTwo`
   - Remote: `/home/mluser/workspace/projects/ProjectTwo`

### How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  Alice's MacBook                     VM (192.168.1.39)                       │
│  ┌─────────────────┐                 ┌─────────────────────────────────┐    │
│  │ PyCharm Pro     │                 │                                 │    │
│  │                 │    SSH Sync     │  ~/workspace/projects/          │    │
│  │ ProjectOne/ ────┼────────────────►│  └── ProjectOne/ ──┐            │    │
│  │                 │                 │                    │            │    │
│  └─────────────────┘                 │                    ▼            │    │
│                                      │  ┌─────────────────────────┐   │    │
│                                      │  │ Container: projectone   │   │    │
│  Bob's MacBook                       │  │ /app ◄── ProjectOne     │   │    │
│  ┌─────────────────┐                 │  │ /data ◄── data/ProjectOne   │    │
│  │ PyCharm Pro     │                 │  │ /models, /outputs       │   │    │
│  │                 │    SSH Sync     │  └─────────────────────────┘   │    │
│  │ ProjectTwo/ ────┼────────────────►│                                │    │
│  │                 │                 │  ┌─────────────────────────┐   │    │
│  └─────────────────┘                 │  │ Container: projecttwo   │   │    │
│                                      │  │ /app ◄── ProjectTwo     │   │    │
│                                      │  │ /data ◄── data/ProjectTwo   │    │
│                                      │  │ /models, /outputs       │   │    │
│                                      │  └─────────────────────────┘   │    │
│                                      │                                 │    │
│                                      │  Shared: Docker image, GPU      │    │
│                                      └─────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Workflow Summary

| Step | Alice (ProjectOne) | Bob (ProjectTwo) |
|------|-------------------|------------------|
| 1. Clone | `git clone .../ProjectOne` | `git clone .../ProjectTwo` |
| 2. Configure | Edit `.env` with `PROJECT_NAME=ProjectOne` | Edit `.env` with `PROJECT_NAME=ProjectTwo` |
| 3. PyCharm | Set deployment path to ProjectOne | Set deployment path to ProjectTwo |
| 4. Code | Edit locally in PyCharm | Edit locally in PyCharm |
| 5. Sync | Auto-sync on save to VM | Auto-sync on save to VM |
| 6. Run | Executes in container on VM | Executes in container on VM |
| 7. Data | Uses `/data` (ProjectOne data) | Uses `/data` (ProjectTwo data) |

### Benefits of This Architecture

| Benefit | Description |
|---------|-------------|
| **Consistent Environment** | Both developers use identical Docker image |
| **GPU Sharing** | Single GPU shared across projects |
| **Large Data Stays on VM** | No need to sync GBs of data to MacBooks |
| **Isolated Projects** | Separate data/models/outputs per project |
| **Fast Iteration** | Code syncs instantly; execution on powerful VM |
| **Work From Anywhere** | Same setup works over VPN/Tailscale |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH connection refused | Check VM IP, ensure SSH is running: `sudo systemctl status ssh` |
| Docker permission denied | Add user to docker group: `sudo usermod -aG docker $USER`, then logout/login |
| PyCharm can't connect to Docker | Verify Docker SSH connection in PyCharm settings |
| Files not syncing | Check PyCharm Deployment settings, ensure "Upload on save" is enabled |
| GPU not detected in container | Verify `nvidia-container-toolkit` installed, use `docker-compose.gpu.yml` |
| Port already in use | Stop conflicting containers: `docker ps` then `docker stop <id>` |
| Container won't start | Check `.env` file exists and has correct paths |
| Python packages missing | Rebuild image: `docker compose build --no-cache` |

---

## License

MIT License
