# template-agent

Technical governance hub and branch-isolated starters for collaborative software engineering with AI coding agents.

**[English](README.md)** | **[Português (Brasil)](README.pt-br.md)**

[![CI](https://github.com/ye-sandbox/template-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/ye-sandbox/template-agent/actions)
[![Release](https://img.shields.io/github/v/release/ye-sandbox/template-agent?color=blue)](https://github.com/ye-sandbox/template-agent/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Architecture: Branch-Isolated Starters](https://img.shields.io/badge/Architecture-Branch--Isolated_Starters-purple.svg)]()

---

## Overview

`template-agent` is the central repository hub providing foundational starter kits and engineering governance protocols for pairing with AI coding agents (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider).

The framework resolves four primary failure modes in autonomous and agentic software workflows:
- **Context Degradation:** Fixed-budget context loading (`AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`) eliminates context window saturation on complex epics.
- **Contract Drift & Hallucination:** Falsifiable definitions of done (DoD), characterization suites, and machine-parseable schemas constrain AI output.
- **Destructive Refactoring:** Chesterton's fences (`INVARIANTS.md`) and surgical diff guardrails prohibit unprompted refactoring on existing codebases.
- **Branch Isolation:** Starters reside as clean, decoupled git branch roots rather than bloated multi-folder monorepos.

Cross-cutting playbooks spanning multiple repositories (UI contracts, HTML prototyping, external browser QA, documentation audits) are maintained centrally in the organizational playbook catalog (`agent-skills`). Starter-specific skills and onboarding workflows remain embedded directly within their respective starter branches.

## Architecture

Templates are partitioned into dedicated, independent branch roots. Merges across specialized branches are forbidden; canonical shared improvements propagate exclusively via atomic cherry-picks.

```mermaid
flowchart TD
    Main["main (Governance & Hub)"]
    Main -.->|"Selective sync / Cherry-pick"| Greenfield["greenfield (From-Scratch Starters)"]
    Main -.->|"Selective sync / Cherry-pick"| Brownfield["brownfield (Legacy Adoption)"]
    Main -.->|"Selective sync / Cherry-pick"| Blackbox["blackbox (Reverse Engineering)"]
    Main -.->|"Selective sync / Cherry-pick"| Infra["infra (Services & Homelab)"]
    Main -.->|"Selective sync / Cherry-pick"| Baremetal["baremetal (Workstation & OS Tuning)"]
```

### Starter Branch Matrix

| Branch | Target Scope | Core Artifacts | Primary Mechanism |
| :--- | :--- | :--- | :--- |
| **`greenfield`** | Clean projects built from scratch | `docs/adr/decisions.md`, `.agent/skills/`, `init.sh` | Clean git root, ADR decision diary, decoupled stack constraints. |
| **`brownfield`** | Existing and legacy codebases | `.agent/INVARIANTS.md`, `.agent/ECOSYSTEM.md`, `install.sh` | Non-destructive injection, Chesterton's fences, Task 00 Discovery. |
| **`blackbox`** | Reverse engineering and closed APIs | `.agent/ENDPOINTS.md`, `.agent/skills/reverse-engineering/`, `init.sh` | Route discovery catalog, replay fixtures, defensive rate limits. |
| **`infra`** | Docker Compose, services, and Homelab | `.agent/SERVICES.md`, `.agent/skills/compose-service/`, `compose.yaml.example` | Service topology, strict healthchecks, memory boundaries. |
| **`baremetal`** | Workstation and host OS tuning | `.agent/BASELINE.md`, `.agent/INVARIANTS.md`, `.agent/TUNINGS.md`, `init.sh` | Rollback-first scripts, system inventory, kernel parameter safety. |
| **`main`** | Hub governance and starter matrix | `AGENTS.md`, `.agent/TASK.md`, `.github/workflows/ci.yml` | Central documentation, drift audits, and ecosystem roadmap. |

## Quickstart

### Prerequisites

- Git 2.30+
- Bash 4.0+
- `curl` 7.60+

### 1. Creating a Project from Scratch (Greenfield)

Initialize a clean project repository with the greenfield starter kit:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/greenfield/init.sh | bash -s -- my-new-project
cd my-new-project
```

*Alternative via Git clone:*
```bash
git clone --depth 1 -b greenfield https://github.com/ye-sandbox/template-agent.git my-new-project
cd my-new-project
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**First prompt for the agent:**
> "Read AGENTS.md, .agent/TASK.md, .agent/NOTES.md, and skills in .agent/skills/. Present your implementation plan for the Active Task in TASK.md before modifying any code."

### 2. Adopting in an Existing Project (Brownfield)

Inject the agent governance harness directly into an existing repository root:

```bash
# Run from the root of your existing repository:
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash
```

*Non-interactive execution:*
```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- -y
```

*Enterprise Stealth Mode (`--local-only`):*
```bash
# Prevents AI files from appearing in git status or shared commits:
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- --local-only
```

**First prompt for the agent:**
> "Read AGENTS.md and .agent/TASK.md. Present your implementation plan for Task [00.1] Project Discovery & Audit before modifying any code."

### 3. Reverse Engineering and Closed Systems (Blackbox)

Scaffold a blackbox environment for API discovery, scraping, or protocol reverse engineering:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/blackbox/init.sh | bash -s -- my-blackbox-project
cd my-blackbox-project
```

*Alternative via Git clone:*
```bash
git clone --depth 1 -b blackbox https://github.com/ye-sandbox/template-agent.git my-blackbox-project
cd my-blackbox-project
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**First prompt for the agent:**
> "Read AGENTS.md, .agent/TASK.md, .agent/ENDPOINTS.md, and .agent/skills/reverse-engineering/SKILL.md. Present your plan for Task [00.1] Authentication Discovery before running live requests."

### 4. Provisioning Infrastructure and Services (Infra)

Initialize an infrastructure repository for Docker Compose stacks and service orchestration:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/infra/init.sh | bash -s -- my-homelab
cd my-homelab
```

*Alternative via Git clone:*
```bash
git clone --depth 1 -b infra https://github.com/ye-sandbox/template-agent.git my-homelab
cd my-homelab
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**First prompt for the agent:**
> "Read AGENTS.md, .agent/SERVICES.md, .agent/TASK.md, and .agent/skills/compose-service/SKILL.md. Present your plan for Task [00.1] Baseline Service Provisioning before altering configuration files."

### 5. PC and Workstation Tuning (Baremetal)

Initialize host administration and workstation tuning with rollback-first safeguards:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/baremetal/init.sh | bash -s -- my-workstation-ops
cd my-workstation-ops
```

*Alternative via Git clone:*
```bash
git clone --depth 1 -b baremetal https://github.com/ye-sandbox/template-agent.git my-workstation-ops
cd my-workstation-ops
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**First prompt for the agent:**
> "Read AGENTS.md, .agent/BASELINE.md, .agent/INVARIANTS.md, and .agent/skills/baremetal-tuning/SKILL.md. Present your implementation plan for Task [00.1] Baseline System Audit & Performance Discovery before running any modification or privileged commands."

## Configuration

Configuration variables defined in `.env.example` along with hub-level environment variables:

| Variable | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `APP_ENV` | Application runtime environment mode (`development`, `production`, `test`) | `development` | No |
| `APP_PORT` | HTTP server listening port | `8000` | No |
| `APP_SECRET_KEY` | Cryptographic secret key for session encryption and signing | `change-me-in-production` | Yes (in production) |
| `DATABASE_URL` | PostgreSQL connection string for primary persistent datastore | `postgresql://user:password@localhost:5432/dbname` | No |
| `REDIS_URL` | Redis connection string for broker, cache, and queue storage | `redis://localhost:6379/0` | No |
| `TEMPLATE_REPO_URL` | Upstream repository URL override for enterprise mirrors and forks | `https://github.com/ye-sandbox/template-agent.git` | No |

## Governance & Decision Matrix

```mermaid
flowchart TD
    A{"What is the project scenario?"}
    A -->|"New Scratch Project"| B["greenfield branch"]
    B --> B1["Decisions recorded in formal ADRs"]
    B --> B2["Unconstrained stack and architecture"]
    B --> B3["Project skills isolated in .agent/skills/"]

    A -->|"Existing Legacy Code"| C["brownfield branch"]
    C --> C1["No retroactive ADRs; Chesterton fences in INVARIANTS.md"]
    C --> C2["Task 00 Discovery maps stack boundaries"]
    C --> C3["Characterization tests required before changes"]
    C --> C4["Surgical diffs with mandatory human gate review"]

    A -->|"Closed / Undocumented System"| D["blackbox branch"]
    D --> D1["Route inventory in .agent/ENDPOINTS.md"]
    D --> D2["Step-by-step reverse engineering playbook"]
    D --> D3["Replay fixtures and payload mocks before code"]
    D --> D4["Defensive rate limits and token scrubbing"]

    A -->|"Services / Homelab / IaC"| E["infra branch"]
    E --> E1["Topology and ports in .agent/SERVICES.md"]
    E --> E2["Standardized compose-service playbook"]
    E --> E3["Mandatory healthchecks and memory boundaries"]
    E --> E4["Guardrails against destructive volume drops"]

    A -->|"Host OS / PC Tuning"| F["baremetal branch"]
    F --> F1["System inventory in .agent/BASELINE.md"]
    F --> F2["Rollback-first: atomic backup and revert scripts"]
    F --> F3["Audited modifications in .agent/TUNINGS.md"]
    F --> F4["Kernel and host parameters guarded by INVARIANTS.md"]
```

## Forks & Enterprise Deployments

For self-hosted instances (GitHub Enterprise, GitLab, Gitea, or private bare Git servers), both `init.sh` and `install.sh` support custom upstream remotes via `TEMPLATE_REPO_URL`:

```bash
# Greenfield from a custom fork
TEMPLATE_REPO_URL="https://github.com/YOUR_ORG/template-agent.git" \
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/template-agent/greenfield/init.sh | bash -s -- my-new-project

# Brownfield from a custom fork
TEMPLATE_REPO_URL="https://raw.githubusercontent.com/YOUR_ORG/template-agent/brownfield" \
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/template-agent/brownfield/install.sh | bash

# Blackbox from a custom fork
TEMPLATE_REPO_URL="https://github.com/YOUR_ORG/template-agent.git" \
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/template-agent/blackbox/init.sh | bash -s -- my-blackbox-project

# Infra from a custom fork
TEMPLATE_REPO_URL="https://github.com/YOUR_ORG/template-agent.git" \
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/template-agent/infra/init.sh | bash -s -- my-homelab
```

### Syncing Forks with Upstream

Synchronize upstream improvements while strictly maintaining branch isolation:

```bash
git remote add upstream https://github.com/ye-sandbox/template-agent.git
git fetch upstream

# Update branches individually (never git merge across different starter branches):
git checkout main && git merge upstream/main
git checkout greenfield && git merge upstream/greenfield
git checkout brownfield && git merge upstream/brownfield
git checkout blackbox && git merge upstream/blackbox
git checkout infra && git merge upstream/infra
git checkout baremetal && git merge upstream/baremetal
```

## Development

### Project Structure

```text
├── .agent/
│   ├── TASK.md               # Active task, execution status, and roadmap log
│   ├── NOTES.md              # Architectural contracts and runtime gotchas
│   ├── ARCHIVE.md            # Archived completed tasks from past releases
│   └── knowledge/            # Modular runtime cards and platform gotchas
├── .github/
│   ├── workflows/ci.yml      # CI workflow for multi-branch matrix validation
│   └── scripts/              # Branch drift and starter contract assertions
├── docs/
│   └── adr/decisions.md      # Consolidated architectural decision records
├── .env.example              # Canonical environment configuration schema
├── AGENTS.md                 # Repository constitution and engineering rules
├── CHANGELOG.md              # Versioned release notes and ecosystem history
├── README.md                 # English documentation
└── README.pt-br.md           # Portuguese (Brasil) documentation
```

### Validation Commands

```bash
# Verify branch governance contracts and file drift across specialized branches
.github/scripts/check-branch-drift.sh

# Run end-to-end scaffolding tests across all starter branches
.github/scripts/test-all-starters.sh

# Verify markdown files and whitespace integrity
git diff --check
```

## License

Released under the [MIT License](LICENSE).
