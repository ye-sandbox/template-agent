# Infrastructure, Services & Homelab Template (ADD)

🌐 **English | [Português](README.pt-br.md)**

This repository serves as the foundation for managing, orchestrating, and evolving **agent-driven infrastructure and Homelab services** (Docker Compose, VictoriaLogs, Uptime Kuma, databases, reverse proxies, and observability).

The governance structure is engineered to eliminate common operational risks when AI agents interact with infrastructure: **port binding collisions**, **accidental volume loss**, **plaintext secret leaks in YAML**, and **missing resource limits**.

---

## 🏛️ Template Structure

```text
├── .agent/
│   ├── ARCHIVE.md               # Archived completed tasks
│   ├── NOTES.md                 # Infrastructure architectural decisions and gotchas
│   ├── SERVICES.md              # Living source of truth: Ports, Volumes, Networks, Healthchecks
│   ├── TASK.md                  # Active task and service evolution roadmap
│   └── skills/
│       ├── 000-template.md      # Template for new standard operating procedures
│       ├── README.md            # Infrastructure skills index
│       └── compose-service/     # Standard procedure for adding/modifying services
├── compose.yaml.example         # Canonical Compose example with healthchecks and limits
├── .env.example                 # Environment variable and port contracts
├── .gitignore                   # Guards against committing data, volumes, and secrets
├── AGENTS.md                    # SRE/DevOps golden rules and non-negotiable guardrails
└── README.md                    # Project documentation
```

---

## 🚀 Quickstart

### 1. Create environment file and configure variables
```bash
cp .env.example .env
# Adjust ports and credentials for your host
```

### 2. Initialize service file from example
```bash
cp compose.yaml.example compose.yaml
```

### 3. Validate Compose syntax
```bash
docker compose config --quiet && echo "Compose syntax valid!"
```

### 4. Launch services in background
```bash
docker compose up -d
docker compose ps
```

---

## 🤖 First Prompt for the AI Agent

When opening this repository in your AI coding environment (Cursor, Windsurf, Antigravity, Roo Code):

> *"Read AGENTS.md, .agent/SERVICES.md, .agent/TASK.md, and .agent/skills/compose-service/SKILL.md. Present your implementation plan for Task [00.1] before altering configuration files."*
