# template-agent

Technical governance hub and branch-isolated starters for collaborative software engineering with AI coding agents.

**[English](README.md)** | **[Português (Brasil)](README.pt-br.md)**

[![CI](https://github.com/ye-sandbox/template-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/ye-sandbox/template-agent/actions)
[![Release](https://img.shields.io/github/v/release/ye-sandbox/template-agent?color=blue)](https://github.com/ye-sandbox/template-agent/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/license/mit)
[![Architecture: Branch-Isolated Starters](https://img.shields.io/badge/Architecture-Branch--Isolated_Starters-purple.svg)](#architecture)

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
| `LLM_BASE_URL` | OpenAI v1-compatible LLM Gateway endpoint URL (Hydra LLM Router) | `http://hydra-llm-router:3000/v1` | No |
| `LLM_API_KEY` | Gateway authentication token corresponding to provisioned tier | `sk-replace-with-hydra-tier-token` | Yes (when LLM enabled) |
| `LLM_MODEL_FAST` | Low-latency virtual model alias for intent classification and parsing | `fast` | No |
| `LLM_MODEL_DEEP` | Reasoning virtual model alias with extended reasoning token budget | `deep` | No |
| `LLM_TIMEOUT_SECONDS` | HTTP client timeout budget in seconds for reasoning completions | `180` | No |
| `TEMPLATE_REPO_URL` | Upstream repository URL override for enterprise mirrors and forks | `https://github.com/ye-sandbox/template-agent.git` | No |

The table lists defaults on `main`. Each starter retains its own `.env.example`; the drift audit checks model aliases against that branch's routing contract. `TEMPLATE_REPO_URL` is an installer override, not an entry in the hub's `.env.example`.

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
│   ├── hooks/                # Standardized project lifecycle hooks (post-worktree-create, pre-verify)
│   └── knowledge/            # Modular runtime cards and platform gotchas
├── .github/
│   ├── workflows/ci.yml      # CI workflow for multi-branch matrix validation
│   └── scripts/              # Branch drift, fast-link bootstrap, contract assertions & LLM linter
├── docs/
│   ├── adr/decisions.md      # Consolidated architectural decision records
│   ├── agent-sandbox.md      # Dual-tier hermetic sandbox & container isolation
│   ├── llm-gateway.md        # OpenAI v1 gateway integration, virtual models & network isolation
│   ├── subagent-topology.md  # 3-tier subagent roles and delegation contracts
│   └── worktree-isolation.md # Worktree lifecycle, fast-link CLI, and lifecycle hooks
├── .env.example              # Canonical environment configuration schema
├── AGENTS.md                 # Repository constitution and engineering rules
├── CHANGELOG.md              # Versioned release notes and ecosystem history
├── README.md                 # English documentation
└── README.pt-br.md           # Portuguese (Brasil) documentation
```

### Adaptive Interface Verification

All five starters include the [interface-testing skill](.agent/skills/interface-testing/SKILL.md) and the shared [Invariant 7](.agent/INVARIANTS.md#7-adaptive-interface-verification--ui-protocol). Brownfield injection installs the skill in both standard and stealth modes, preserving existing files unless an overwrite flag is supplied.

Load the skill only for UI, preview, or frontend component work. In T3 Code, the contract covers preview/device checks, snapshot locators, and session cleanup. In headless CLI/CI, use non-blocking build, component, and headless E2E checks. Static documentation research uses HTTP/search tools.

The drift audit compares the skill byte for byte and compares only Invariant 7, preserving each starter's other fences. Generated-project assertions verify that the skill, all four guardrails, and the UI context/DoD directives reach installed projects.

### Sequential Sub-Task Batching & Hermetic Skills

To preserve prompt cache prefixes across dependent subtasks, group 2–4 sequential same-layer subtasks under `[BATCH: Bx]` anchored to an untracked specification in `.agent/scratch/specs/XX-YY.md`. `.github/scripts/bootstrap-worktree.sh` copies `.agent/scratch/specs/` into isolated worktrees, while `.github/scripts/verify-microcontract.sh` (`verify-batches`) enforces 2–4 cardinality and blocks mixing backend code (`Type: code` touching backend/API/database paths) with UI or `browser-qa`/`mobile-qa`/`preview-mockup` layers.

Under the Hermetic Skills & Context Contract, procedural skills must reside in `.agent/skills/` or be injected into the task prompt rather than searched across the host filesystem. `.github/scripts/check-branch-drift.sh` enforces parity of both `[BATCH: Bx]` / `.agent/scratch/specs/` contracts and the Hermetic Skills directives across `main` and all five starters.

### Ecosystem Governance Tools

Python 3 is required. Run these tools from a checkout of the hub's `main` branch: interface auditing and opt-in migration read the canonical skill and invariants from that checkout. The auditor reads project files without changing them; its heuristic score does not certify application behavior.

```bash
python3 .github/scripts/audit-ecosystem-standards.py /path/to/project --format markdown --output /tmp/governance-audit.md
python3 .github/scripts/audit-ecosystem-standards.py /path/to/project --format json --fail-under 90
python3 .github/scripts/apply-governance-standards.py /path/to/project --dry-run
```

Both tools accept a repository path or a directory of repositories, with `--dir`/`-d` as an alternative to the positional path. Omitting the path scans `~/github`. Directory scans exclude repository names containing `template-agent`, `agent-skills`, `.github`, `yegear1`, or `org-ye-sandbox`; `--exclude NAME ...` replaces that list, and `--no-exclude` disables it. A direct repository target bypasses name exclusions. Only migration supports `--repo NAME`, an exact repository-name filter; only the auditor supports `--max-depth` (default `4`), `--format table|markdown|json`, `--output`, and `--verbose`.

The audit retains its existing report fields and adds interface checks for canonical skill bytes, all four Invariant 7 blocks, the on-demand context reference, and the dual-runtime UI DoD. Scores are rounded from `(legacy points + interface points) / 120 * 100`: the legacy rubric contributes 100 points and interface checks contribute 20. A project passing every legacy check but no interface checks scores 83. `--fail-under N` exits `1` when the average score of the discovered, included repositories is below `N`; an empty result does not trigger that failure.

Default migration behavior remains ADR consolidation, NOTES cleanup, collaboration contracts, and governance directives. Supported legacy Markdown ADRs are consolidated without discarding distinct decisions that share a title; unsupported assets, unsafe paths, or unreadable content block ADR cleanup and retain the source tree with diagnostics. This is separate from the interface opt-in below.

To add interface contracts, preview and then apply the same explicit flag:

```bash
python3 .github/scripts/apply-governance-standards.py /path/to/project --include-interface-contracts --dry-run
python3 .github/scripts/apply-governance-standards.py /path/to/project --include-interface-contracts
```

The opt-in installs the canonical [interface-testing skill](.agent/skills/interface-testing/SKILL.md), adds missing shared Invariants 7.1–7.4, and adds the runtime-aware AGENTS context/DoD directives. It preserves project-specific invariants and failure thresholds. Dry-run writes nothing; reapplying unchanged, complete contracts produces no diff. This flag also runs the default governance transformations; review their proposed changes too.

Custom skill bytes, divergent or duplicate shared invariants, custom interface directives, ambiguous sections, and unreadable or symlinked interface paths require manual reconciliation. A failed interface preflight leaves that repository unchanged and reports the path or contract to review; resolve the diagnostic and rerun dry-run. The CLI exits `1` if any interface migration is blocked, while other repositories in the same scan may still be processed.

CI runs the audit and migration self-tests on Ubuntu and macOS. The migration self-test includes the disposable fixtures in [test_interface_migration.py](.github/scripts/tests/test_interface_migration.py), covering preservation, conflicts, dry-run, repeat application, and interface audit compliance.

### Validation Commands

```bash
# Verify branch governance contracts and file drift across specialized branches
.github/scripts/check-branch-drift.sh

# Exercise drift detection against disposable local Git refs
bash .github/scripts/test-branch-drift.sh

# Validate micro-contract definitions and git worktree isolation guardrails
.github/scripts/verify-microcontract.sh

# Audit command security and blast-radius guardrails
.github/scripts/audit-command-security.sh

# Bootstrap worktree fast-link symlinks (.venv, node_modules) and run lifecycle hooks
.github/scripts/bootstrap-worktree.sh --self-test

# Validate LLM gateway contracts, network isolation, and virtual model routing
.github/scripts/verify-llm-contract.sh self-test

# Validate ecosystem auditing and migration with hermetic fixtures
python3 .github/scripts/audit-ecosystem-standards.py --self-test
python3 .github/scripts/apply-governance-standards.py --self-test
python3 .github/scripts/audit-ecosystem-standards.py . --no-exclude --fail-under 90

# Run end-to-end scaffolding tests across all starter branches
.github/scripts/test-all-starters.sh

# Verify markdown files and whitespace integrity
git diff --check
```

## License

Released under the [MIT License](https://opensource.org/license/mit).
