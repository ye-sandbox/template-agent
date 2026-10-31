# Brownfield Starter Kit

Technical governance framework for introducing AI coding agents safely into existing production repositories.

**[English](README.md)** | **[Português (Brasil)](README.pt-br.md)**

[![CI](https://github.com/ye-sandbox/template-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/ye-sandbox/template-agent/actions)
[![Starter: Brownfield](https://img.shields.io/badge/Starter-Brownfield-amber.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Overview

The Brownfield starter kit provides a structured governance harness for introducing AI coding agents (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider) into established, production codebases without risking regressions or violating unspoken architectural contracts.

Unlike Greenfield projects where agents design systems freely, Brownfield repositories operate under strict constraints:
- **Non-Destructive Injection:** The template injects governance scaffolding into existing project trees without touching source code or dependency manifests.
- **Chesterton's Fences:** Critical system quirks, frozen dependencies, and domain invariants are recorded in `.agent/INVARIANTS.md` to prevent accidental refactoring.
- **Enterprise Stealth Mode:** The `--local-only` flag stores all agent configuration inside `.git/info/exclude`, leaving `.gitignore` untouched and git status 100% clean.
- **Task 00 Discovery:** A dedicated bootstrap protocol maps repository entrypoints, package managers, and test suites into `AGENTS.md` before code changes begin.

## Architecture

```mermaid
flowchart TD
    Inject["install.sh (Inject Governance)"] --> Task00["Task 00 Discovery & Audit"]
    Task00 --> Calibrate["Calibrate AGENTS.md & INVARIANTS.md"]
    Calibrate --> Task["Active Roadmap Task in TASK.md"]
    Task --> Characterize["Characterization Tests (Prove Current Behavior)"]
    Characterize --> Plan["Agent Implementation Plan"]
    Plan --> Gate{"Human Review Gate"}
    Gate -->|"Approved"| Code["Surgical Diff Implementation"]
    Gate -->|"Revisions Requested"| Plan
    Code --> Verify["Verification (Existing Suites + DoD)"]
    Verify --> Commit["Atomic Commit (Local / Human Push Gate)"]
```

### Injected Directory Structure

```text
├── AGENTS.md                 # Constitution for legacy code (non-regression rules, surgical scope)
├── install.sh                # Injection installer for existing repositories
├── docs/adr/decisions.md     # Architectural Decision Records (ADR log)
└── .agent/
    ├── TASK.md               # Active task (initialized with Task 00 Discovery)
    ├── INVARIANTS.md         # Untouchable behaviors, frozen dependencies, and justified quirks
    ├── NOTES.md              # Mapped active contracts, entrypoints, and gotchas
    ├── ARCHIVE.md            # Completed task history preserving lean context
    ├── ECOSYSTEM.md          # Multi-repo topology, cross-service contracts, and boundaries
    └── knowledge/            # Modular runtime gotchas and platform cards
        ├── 000-schema.md     # Knowledge card specification
        └── k-000-template.md # Template for runtime cards
```

## Quickstart

### Prerequisites

- Git 2.30+
- Bash 4.0+
- `curl` 7.60+

### Injecting into an Existing Repository

Execute the installer directly from the root of your existing codebase:

```bash
# Standard automated injection
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash
```

```bash
# Non-interactive automated injection (for CI or unattended setup)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- -y
```

```bash
# Enterprise Stealth Mode (local-only, hides all AI governance from git status)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- --local-only
```

*Alternative via local script execution:*

```bash
./install.sh /path/to/existing-project
# or with enterprise stealth mode:
./install.sh --local-only /path/to/existing-project
```

### Discovery Kickoff Prompt

Provide this prompt to your AI coding agent immediately after injection:

> "Read AGENTS.md and .agent/TASK.md. Present your implementation plan for Task [00.1] Project Discovery & Audit before modifying any code."

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

### Core Brownfield Invariants

1. **Characterization Tests First:** When modifying legacy functions lacking tests, write a characterization test proving existing behavior before altering any application logic.
2. **Zero Opportunistic Refactoring:** Keep diffs surgical. Never reformat untouched files, clean whitespace, or alter adjacent conventions.
3. **Mandatory Human Review Gate:** In production legacy codebases, autonomous pushes to shared remotes are forbidden. All commits require human sign-off.
4. **Preserve Invariants:** Consult `.agent/INVARIANTS.md` before altering code that appears suboptimal or redundant.

## Development

### Validation Commands

```bash
# Verify repository formatting and whitespace integrity
git diff --check
```

## License

Released under the [MIT License](LICENSE).
