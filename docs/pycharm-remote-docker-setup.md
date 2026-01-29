# PyCharm Pro + Remote Docker Setup Analysis

## What is Mutagen?

Mutagen is a **file synchronization tool** for developers:
- Syncs files between local machine and remote server in real-time
- Designed for "code local, run remote" workflows
- Fast, bidirectional, handles conflicts

**But you don't need it** if you're using PyCharm Pro.

---

## PyCharm Pro Remote Development

PyCharm Pro has everything built-in:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     PyCharm Pro Built-in Features                        │
│                                                                          │
│  ┌──────────────────┐         ┌──────────────────────────────────────┐  │
│  │ Your MacBook     │         │ VM (192.168.1.39)                    │  │
│  │                  │         │                                      │  │
│  │  PyCharm Pro     │         │  ┌─────────────────────────────────┐ │  │
│  │  ┌────────────┐  │   SSH   │  │ /home/user/projects/ml-project  │ │  │
│  │  │ Local code │──┼────────►│  │ (auto-synced by PyCharm)        │ │  │
│  │  └────────────┘  │  Sync   │  └─────────────────────────────────┘ │  │
│  │                  │         │                                      │  │
│  │  ┌────────────┐  │  SSH/   │  ┌─────────────────────────────────┐ │  │
│  │  │ Remote     │──┼────────►│  │ Docker Container (ml-dev)       │ │  │
│  │  │ Interpreter│  │  Docker │  │ Python interpreter here         │ │  │
│  │  └────────────┘  │         │  └─────────────────────────────────┘ │  │
│  │                  │         │                                      │  │
│  └──────────────────┘         └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### PyCharm Pro Handles:

| Feature | What It Does |
|---------|--------------|
| **Deployment** | Auto-syncs code to VM on save |
| **Remote Interpreter** | Runs Python inside Docker container on VM |
| **Docker Integration** | Connects to remote Docker daemon |
| **Debugging** | Full debugging in remote container |
| **Terminal** | SSH terminal to VM/container |

---

## Revised Approach (Simpler)

Since you're using PyCharm Pro, the architecture becomes:

```
┌────────────────┐         ┌────────────────────────────────────┐
│   MacBook      │         │   VM (192.168.1.39)                │
│                │         │                                    │
│  PyCharm Pro   │         │   ~/projects/ml-project-template/  │
│  - Edit code   │───SSH──►│   (synced files live here)         │
│  - Git         │  Sync   │                                    │
│                │         │   Docker Container (ml-dev)        │
│  Run/Debug ────┼───SSH──►│   - Python interpreter             │
│                │  Docker │   - All ML libraries               │
│                │         │   - Mounts synced folder           │
└────────────────┘         └────────────────────────────────────┘
```

### What You Configure in PyCharm:

1. **Deployment (File Sync)**
   - Tools → Deployment → Configuration
   - Add SFTP connection to VM
   - Set auto-upload on save

2. **Remote Docker**
   - Settings → Build, Execution, Deployment → Docker
   - Add Docker connection via SSH: `ssh://user@192.168.1.39`

3. **Remote Interpreter**
   - Settings → Project → Python Interpreter
   - Add Interpreter → On Docker Compose
   - Point to remote Docker + your `docker-compose.yml`

---

## Revised Changes Needed

| File | Change |
|------|--------|
| `.env.example` | Add `DOCKER_VM_IP`, `DOCKER_VM_USER`, `DOCKER_VM_PROJECT_PATH` |
| `docker-compose.yml` | Change bind mount to `${DOCKER_VM_PROJECT_PATH}:/app` |
| `Makefile` | Add VM-related convenience targets |
| `README.md` | Add PyCharm remote setup instructions |

**No Mutagen needed.**

---

## What Stays the Same

- `Dockerfile` — no changes
- `docker-compose.gpu.yml` — no changes
- Container runs on VM with GPU access
- All Docker commands work (just point to remote daemon)

---

## Summary

| Before (Mutagen approach) | Now (PyCharm Pro approach) |
|---------------------------|----------------------------|
| Mutagen for file sync | PyCharm Deployment (built-in) |
| Docker context CLI setup | PyCharm Docker settings |
| Manual configuration | GUI-based setup in PyCharm |
| Works with any editor | Optimized for PyCharm |

---

## Next Steps

When ready, implement:
1. Environment variables for VM configuration
2. Update docker-compose.yml bind mount
3. Add PyCharm setup documentation to README
