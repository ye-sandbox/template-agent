# Greenfield Starter Kit

Technical foundation for building software from scratch with AI coding agents.

**[English](README.md)** | **[Português (Brasil)](README.pt-br.md)**

[![CI](https://github.com/ye-sandbox/template-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/ye-sandbox/template-agent/actions)
[![Starter: Greenfield](https://img.shields.io/badge/Starter-Greenfield-success.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Overview

The Greenfield starter kit provides a clean foundation for developing new applications, microservices, and libraries using AI coding agents (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider). Greenfield projects begin with an unconstrained architectural setup governed by formal Architectural Decision Records (ADRs) and strict Definition of Done (DoD) verification gates.

The starter resolves key failure modes in agent-driven development:
- **Context Preservation:** Enforces fixed-budget context loading (`AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`), archiving completed tasks to `.agent/ARCHIVE.md`.
- **Architectural Traceability:** Retains durable architectural decisions in `docs/adr/decisions.md` while keeping active operational notes lean.
- **Modular Extension:** Supports isolated domain procedures in `.agent/skills/` and runtime gotcha capture in `.agent/knowledge/`.
- **Automated Scaffolding:** Provisions a fresh Git repository and clean product documentation via `init.sh` in a single command.

## Architecture

```mermaid
flowchart TD
    Task["TASK.md (Active Task)"] --> Plan["Agent Implementation Plan"]
    Plan --> Review{"Human Approval"}
    Review -->|"Approved"| Running["Status: RUNNING"]
    Review -->|"Revisions Requested"| Plan
    Running --> Code["Implementation & Tests"]
    Code --> DoD["Definition of Done (100% Tests Pass)"]
    DoD --> Commit["Conventional Commit in English"]
    Commit --> Done["Log to Completed Tasks & Promote Next"]
```

### Directory Layout

```text
├── AGENTS.md                 # Project constitution (rules, stack, MCPs, validation gates)
├── .agent/
│   ├── TASK.md               # Active task, acceptance criteria, and immediate roadmap
│   ├── NOTES.md              # Rapid architectural decisions, contracts, and gotchas
│   ├── ARCHIVE.md            # Completed tasks history preserving lean context
│   ├── ECOSYSTEM.md          # Multi-repo topology and service boundaries (optional)
│   ├── knowledge/            # Modular runtime gotchas and platform cards
│   │   ├── 000-schema.md     # Knowledge card specification
│   │   └── k-000-template.md # Template for runtime cards
│   └── skills/               # Specialized procedural skills for the project
│       ├── README.md         # Guide on skill creation and usage
│       └── 000-template.md   # Standard SKILL.md template
├── docs/
│   └── adr/
│       └── decisions.md      # Consolidated Architectural Decision Records (ADR log)
├── .env.example              # Canonical environment variable contract
├── .gitignore                # Comprehensive defaults (Node, Python, Docker, agent caches)
├── init.sh                   # Scaffolding script for new project repositories
└── README.md                 # Starter documentation
```

## Quickstart

### Prerequisites

- Git 2.30+
- Bash 4.0+
- `curl` 7.60+

### Scaffolding a New Project

Execute the one-liner initialization script from your terminal:

```bash
# Standard scaffolding (includes multi-repo ECOSYSTEM.md)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/greenfield/init.sh | bash -s -- my-new-project
cd my-new-project
```

```bash
# Standalone mode (omits multi-repo ECOSYSTEM.md)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/greenfield/init.sh | bash -s -- --standalone my-new-project
cd my-new-project
```

*Alternative via manual Git clone:*

```bash
git clone --depth 1 -b greenfield https://github.com/ye-sandbox/template-agent.git my-new-project
cd my-new-project
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

### Kickoff Prompt

Provide this prompt to your AI coding agent during the first turn:

> "Read AGENTS.md, .agent/TASK.md, .agent/NOTES.md, and skills in .agent/skills/. Present your implementation plan for the Active Task in TASK.md before modifying any code."

## Configuration

The template provides canonical configuration schemas via `.env.example`:

| Variable | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `APP_ENV` | Application runtime environment mode (`development`, `production`, `test`) | `development` | No |
| `APP_PORT` | HTTP server listening port | `8000` | No |
| `APP_SECRET_KEY` | Cryptographic secret key for session encryption and signing | `change-me-in-production` | Yes (in production) |
| `DATABASE_URL` | PostgreSQL connection string for primary persistent datastore | `postgresql://user:password@localhost:5432/dbname` | No |
| `REDIS_URL` | Redis connection string for broker, cache, and queue storage | `redis://localhost:6379/0` | No |

## Usage

### Task Lifecycle Protocol

1. **Task Definition:** Define the target objective in `Active Task` inside `.agent/TASK.md` with explicit acceptance criteria.
2. **Plan-First Review:** The agent sets status to `PLANNING` and presents an implementation plan. Await user confirmation before code modification.
3. **Execution & Validation:** Update status to `RUNNING`. Execute implementation, running validation commands until 100% passing.
4. **Completion:** Commit changes with an atomic Conventional Commit (`feat(...)`, `fix(...)`), log completion in `.agent/TASK.md`, and promote the next task.

## Development

### Validation Commands

```bash
# Verify repository formatting and whitespace integrity
git diff --check

# Execute local project test suite (configure in AGENTS.md during Task 00.1)
npm test
```

## License

Released under the [MIT License](LICENSE).
