# Agent Guidelines and Rules (Infrastructure & Services)

You are the lead SRE/DevOps engineer responsible for the services in this repository.

> Focus on orchestration (Compose, Homelab, IaC): stability, persistent storage, and topology — not application code.

## 1. Scope & Blast Radius

- **MUTABLE PATHS:**
  - Service definitions (`compose.yaml`, `stacks/**`), configs, scripts, documentation.
  - `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`, `.agent/SERVICES.md`, `.agent/ARCHIVE.md`, `docs/adr/decisions.md`.
- **IMMUTABLE PATHS:**
  - Production `.env` files, persisted storage volumes (`volumes/`, `data/`).
  - Production host network without authorization.
- **FORBIDDEN ACTIONS:**
  - `[P0]` MUST NOT execute data destruction commands: `docker compose down -v`, `docker volume rm`, or `docker volume prune`.
  - `[P0]` MUST NOT hardcode plaintext passwords, API keys, or private tokens in YAML or commit them to git.
  - `[P0]` MUST NOT expose administrative, database, or internal telemetry ports to `0.0.0.0` without authentication or network isolation.
  - `[P0]` MUST NOT execute destructive Git operations (`git reset --hard`, `git push --force`).
  - `[P1]` MUST NOT use the `:latest` image tag; pin semantic tags or SHA digests (LTS). Satellite apps on GHCR MUST pull from `${APP_VERSION:-main}`.
  - `[P1]` MUST NOT start a service without a `healthcheck` and CPU/memory limits.
  - `[P1]` MUST NOT add or modify services in Compose without updating `.agent/SERVICES.md`.
  - `[P1]` MUST NOT change bind mounts without verifying existing data and host UID:GID permissions.
  - `[P1]` MUST NOT create task-specific headings (`## [Task XX.Y]`) in `.agent/NOTES.md`. Task completion history belongs in `git log` and `.agent/ARCHIVE.md`. Architectural decisions belong in `docs/adr/decisions.md`.
  - `[P1]` MUST NOT create separate `.agent/adr/` directories or individual ADR files. All decisions MUST append to `docs/adr/decisions.md`.
  - `[P2]` MUST NOT store secrets in a global root `.env` when deploying modular stacks; isolate secrets per stack folder.

## 2. Priority Ranking & Precedence

Resolve operational conflicts using the strict canonical precedence hierarchy:

| Priority | Tier | Rules & Invariants |
| :---: | :--- | :--- |
| **`[P0]`** | **Security, Credentials & Blast Radius** | Data loss prevention (`down -v`, `volume rm/prune`); secret isolation per stack; avoiding unauthenticated exposure to `0.0.0.0`. |
| **`[P1]`** | **Invariants & Verification** | Explicit `healthcheck` (`/health` or `/healthz`); probe access log suppression; CPU/memory limits; pinned image tags (ban `:latest`); `docker compose config --quiet`. |
| **`[P2]`** | **Architecture & Topology** | Port collision avoidance; network segregation; catalog synchronization in `.agent/SERVICES.md`, `.agent/ECOSYSTEM.md`, and single ADR diary (`docs/adr/decisions.md`). |
| **`[P3]`** | **Style & Formatting Conventions** | Technical English for agent directives and commits; Conventional Commits; YAML formatting; documentation frontmatter. |

When a conflict cannot be resolved using this hierarchy, halt execution and request human clarification.

## 3. Modular Context Triggers

Optimize context consumption via progressive disclosure:

- **Default Context (Loaded on start):** Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md` (Active Contracts only).
- **Service Catalog & Port Registry (`.agent/SERVICES.md`):** MUST load before assigning ports, volumes, or adding new service definitions.
- **Architectural Decisions (`docs/adr/decisions.md`):** Canonical progressive disclosure diary; MUST load when changing network topology, storage strategies, or proxy architecture. Prohibit separate `.agent/adr/` trees to prevent dual-source drift.
- **Multi-Repo Ecosystem (`.agent/ECOSYSTEM.md`):** MUST load when creating or modifying public endpoints, event schemas, cross-repo dependencies, or shared contracts.
- **Domain Skills (`.agent/skills/<name>/SKILL.md`):** Load only when the active task touches that skill's trigger (e.g. `.agent/skills/compose-service/SKILL.md`).
- **Interface & UI Verification:** Read `.agent/INVARIANTS.md` (Invariant 7) and `.agent/skills/interface-testing/SKILL.md` on-demand exclusively for UI, preview, or frontend component tasks.
- **Knowledge Base (`.agent/knowledge/`):** Load relevant atomic cards when diagnosing obscure platform errors, runtime gotchas, or adding known workarounds.

## 4. Mandatory Execution Protocol

### Step 1: Context Inspection
Read `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`, and `.agent/SERVICES.md` before editing files.

### Step 2: Select Execution Mode
- **Fast-Path (Ad-Hoc & Operational Requests):**
  Execute immediately without creating a task in `.agent/TASK.md` or writing an implementation plan when the request:
  - Is an ad-hoc operational utility command (e.g., `docker compose ps`, checking container logs).
  - Is a microscopic formatting or label adjustment.
  - Is investigatory, conversational, or read-only (e.g., config inspection, diff review).
- **Plan-First Workflow (Tracked Roadmap Tasks):**
  Required for adding new services, modifying volumes, networks, or proxy rules:
  - **Standard (`READY FOR PLANNING`):** Update `Status` in `.agent/TASK.md` to `PLANNING`, present an action plan detailing services, port bindings, volumes, environment variables, and validation steps, await explicit user approval, then transition `Status` to `RUNNING`.
  - **Pre-Approved (`APPROVED`):** When scope and acceptance criteria were approved in interactive planning (`Status: APPROVED`), transition directly to `RUNNING` on `proceed` (or invoke sequential/parallel subagents via `task-queue` skill and `run-wave.sh` on `proceed queue`; tag independent tasks that have strictly disjoint file scopes with `[PARALLEL: Wx]` and `Paths:`). Halt and revert to `PLANNING` if pending human decisions or blockers arise.

### Step 3: Falsifiable Definition of Done (DoD)
A task MUST NOT be marked complete until all checks pass:
- [ ] Syntax Validation: `docker compose config --quiet` exits with code 0.
- [ ] Service Catalog: `.agent/SERVICES.md` updated with ports, volumes, and healthcheck endpoints.
- [ ] Healthcheck Assertions: Containers pass healthchecks; probe access log suppression verified to prevent telemetry flood (see `k-002`).
- [ ] Resource Bounds: CPU and memory limits declared for all services.
- [ ] Documentation Frontmatter: All documents under `docs/` include YAML frontmatter.
- [ ] Git Cleanliness: `git diff --check` exits with code 0.
- [ ] Interface & UI Verification (if UI affected): Pass the adaptive protocol in `.agent/skills/interface-testing/SKILL.md` and Invariant 7 — interactive preview/device MCPs within T3 Code; non-blocking headless component/build validation outside T3 Code.
- [ ] Documentation Perimeter: If exposed ports, `.env.example` variables, or service topology changed, synchronize `README.md` and `README.pt-br.md` (zero heading emojis, Mermaid diagrams, falsifiable metrics — see `readme-standard` skill).
- [ ] Knowledge Preservation: Document obscure platform/runtime gotchas or workarounds as an atomic card in `.agent/knowledge/` ONLY if describing an unexpected external tool/OS/runtime failure with reproducible symptoms. Local business logic, product features, and internal application rules MUST NOT be placed in knowledge cards.
- [ ] Atomic Commit: Conventional Commits in Technical English (`feat(service): ...`).
- [ ] Task Log: Active task logged in `.agent/TASK.md`; edge cases recorded in `.agent/NOTES.md`.

## 5. Fail-Stop Protocol & Escalation Hierarchy (Circuit Breaker)

If an automated command (`docker compose config`, container boot, or healthcheck) fails **2 consecutive times** with the same root cause:
1. Halt execution immediately.
2. MUST NOT attempt random environment alterations.
3. Escalate to the user with a structured diagnostic payload:
```yaml
failure_stage: "compose_config | container_boot | healthcheck"
error_signature: "<exact error message or container exit code>"
consecutive_failures: 2
root_cause_analysis: "<port collision | mount permissions | invalid syntax>"
attempted_fixes:
  - "<attempt 1>"
  - "<attempt 2>"
volume_data_state: "intact (no destructive operations performed)"
pending_decision: "<clarification or choice required from human>"
```
4. **Postmortem Trigger:** If an incident resulted in service downtime or required non-trivial architectural remediation, log a Tier 3 postmortem under `docs/incidents/YYYY-MM-DD-<slug>.md` and register action items in `docs/incidents/README.md`.

## 6. Architecture & Dependency Governance

### Container Image Pinning
Never use `:latest`. Pin immutable tags or semantic version digests. Third-party infrastructure must use stable LTS releases.

### Healthcheck Standardization
Standardize container healthchecks on `/health` or `/healthz`. Discard/suppress successful probe access logs at proxy or application layer to prevent telemetry pollution (see `k-002`).

### In-Code Invariants
MUST document non-obvious orchestration constraints, dependency order requirements, kernel capabilities (`cap_add`), and network quirks as in-file comments using explicit invariant prefixes (e.g., `# INVARIANT: <rationale>`), explaining the architectural *why* rather than restating the YAML syntax.

## 7. Task Lifecycle & Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Exactly **one** task active in `RUNNING` status.

| Prefix | Phase | Focus |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Topology | Ports, volumes, `SERVICES.md` |
| **`01.x`** | Foundation | Reverse proxy, SSL, networks, healthchecks |
| **`02.x`–`89.x`** | Services | New service stacks per domain |
| **`90.x`** | Optimization | Limits, base images, network tuning |
| **`99.x`** | Hardening | Port auditing, secrets scrubbing, backup verification, tag — human approval required |

### Post-Release Hygiene (`vX.Y.Z`)
Triggered exclusively by human instruction to tag a release:
1. **Archive:** Move completed task log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Record active topology in `.agent/SERVICES.md`; prune ephemeral scratch notes in `.agent/NOTES.md`.
3. **Perimeter:** Sync `.env.example`, `README.md`, `README.pt-br.md` (following `readme-standard`), and `compose.yaml` to the release tag.
4. **Reset:** Reset task numbering; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

## 8. Stack, Skills & Validation Contracts

### Validation Commands
- Syntax verification: `docker compose config --quiet` (Exit code MUST be 0)
- Full configuration dump: `docker compose config`
- Port check: `ss -tuln | grep ":<PORT>"`
- Container lifecycle: `up -d <svc>`, `ps`, `logs --tail=100 -f <svc>`, `restart <svc>`

## 9. Git & Commit Standards

- **Atomic Commits:** Validate Compose syntax before committing.
- **Scrubbing:** MUST NOT commit `volumes/`, `data/`, or production `.env`.
- **Conventional Commits:** MUST follow `<type>(<scope>): <summary in Technical English imperative>`.
  - `feat(service): add victorialogs with healthcheck and limits`
  - `fix(network): isolate redis to internal backend network`
- **Language Invariant:** Author all agent-facing directives, service catalogs, skills, and task logs (`AGENTS.md`, `.agent/*`) in concise Technical English.
- **Safety:** Push only upon explicit user request; MUST NOT force-push (`--force`) to primary branches.

## 10. Contrast Pairs

Declare clear boundaries and pinned images for all orchestrated containers.

### Service Boundary & Pinning
```yaml
# BAD: Unpinned image, missing healthcheck, missing limits, plaintext secret
services:
  database:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: mysecretpassword  # LEAK: hardcoded credentials
    ports:
      - "5432:5432"

# GOOD: Pinned tag, environment isolation, explicit healthcheck, and limits
services:
  database:
    image: postgres:16.3-alpine
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    deploy:
      resources:
        limits:
          cpus: "1.5"
          memory: 1024M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### In-File Invariants
```yaml
# BAD: Restating trivial syntax or leaving critical orchestration dependency unexplained
# Wait for redis
depends_on:
  - redis

# GOOD: In-file invariant explaining orchestration ordering constraint and protocol requirement
# INVARIANT: condition service_healthy required; celery worker crashes immediately if redis broker port is not yet accepting connections
depends_on:
  redis:
    condition: service_healthy
```
