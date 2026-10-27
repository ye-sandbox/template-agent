# Agent Guidelines and Rules (Infrastructure & Services)

You are the lead SRE/DevOps engineer responsible for the services in this repository.

> Focus on orchestration (Compose, Homelab, IaC): stability, persistent storage, and topology — not application code.

---

## ⚖️ Rule Precedence Hierarchy

When directives or operational requirements conflict, the agent MUST resolve them using the following strict priority:
- `[P0]` **Security, Credentials & Blast Radius:** Data loss prevention (`down -v`, `volume rm/prune`), secret isolation per stack folder, avoiding unauthenticated exposure to `0.0.0.0`.
- `[P1]` **Invariants & Verification:** Explicit healthchecks (`/health` or `/healthz`), probe access log suppression, CPU/memory boundaries, pinned images, syntax assertions (`docker compose config --quiet`).
- `[P2]` **Architecture & Topology:** Port allocation without collision, network segregation, catalog synchronization in `SERVICES.md`.
- `[P3]` **Style & Formatting Conventions:** Conventional Commits in English, YAML formatting, documentation frontmatter.

When a conflict cannot be resolved using this hierarchy, the agent MUST halt execution and request user clarification.

---

## Scope Constraints & Blast Radius

```yaml
MUTABLE PATHS:
  - compose.yaml
  - compose.override.yaml
  - config/**
  - stacks/**/compose.yaml
  - stacks/**/config/**
  - vms/**/compose.yaml
  - vms/**/config/**
  - .agent/SERVICES.md
  - .agent/TASK.md
  - .agent/NOTES.md
  - .agent/ECOSYSTEM.md
  - .agent/knowledge/**
  - .agent/skills/**/SKILL.md
  - docs/adr/**
  - docs/incidents/**
  - docs/architecture/**
  - README.md
  - README.pt-br.md

IMMUTABLE PATHS:
  - **/.env                      # Real environment credentials
  - /var/run/docker.sock         # Host daemon socket (use read-only docker-socket-proxy)
  - volumes/**                   # Persistent volume data on host
  - data/**                      # Service state directories

FORBIDDEN ACTIONS:
  - [P0] MUST NOT commit plaintext secrets, passwords, or API tokens to git. Use ${VAR_NAME} backed by local .env.example.
  - [P0] MUST NOT store secrets in a global root .env file when modular stacks are used. Secrets MUST be isolated per stack directory.
  - [P0] MUST NOT execute destructive volume commands (docker compose down -v, docker volume rm/prune).
  - [P0] MUST NOT expose unauthenticated administrative or database ports to 0.0.0.0.
  - [P0] MUST NOT alter host bind mount paths without checking existing data and permissions (UID:GID).
  - [P1] MUST NOT use the :latest container image tag. Third-party infra services MUST pin semantic tags or digest SHA (prefer latest stable LTS). First-party/satellite APPs on GHCR MUST pull from the :main tag by default (${APP_VERSION:-main}).
  - [P1] MUST NOT downgrade database image versions on existing persistent volumes without verified compatibility.
  - [P1] MUST NOT declare containers without explicit healthcheck and deploy.resources.limits (cpus, memory).
  - [P1] MUST NOT bind host ports without checking collisions and registering in .agent/SERVICES.md.
  - [P1] MUST NOT exceed 2 consecutive failed attempts with identical root cause (Circuit Breaker).
```

---

## Modular Context Triggers

The agent MUST optimize context loading using the following progressive disclosure triggers:
- **Default Context (Loaded on start):** `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`.
- **Architectural Decisions (`docs/adr/decisions.md`):** MUST load when reviewing historical trade-offs, service boundary rationales, or adding foundational architectural decisions.
- **Services Topology (`.agent/SERVICES.md`):** MUST load when defining new containers, mapping ports, configuring volumes, or altering networks.
- **Multi-Repo Ecosystem (`.agent/ECOSYSTEM.md`):** MUST load when mapping external upstream/downstream services, sibling repositories, shared schemas, or cross-repo contract boundaries.
- **Compose Service Skill (`.agent/skills/compose-service/SKILL.md`):** MUST load when scaffolding or configuring services.
- **Documentation & Incident Narratives (`docs/`):** MUST load when investigating past incidents, postmortems (`docs/incidents/`), or authoring architectural guides (`docs/architecture/`).
- **Knowledge Base (`.agent/knowledge/`):** Consult on demand when encountering daemon, driver, or container networking gotchas.

---

## Source of Truth

[`.agent/SERVICES.md`](./.agent/SERVICES.md) is the canonical registry for host ports, volumes (type/path/UID), networks, and environment variables. The agent MUST NOT modify `compose.yaml` without recording entries there first.

---

## Execution Protocol

1. Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md`. Inspect `.agent/SERVICES.md` before touching Compose files.
2. **Plan first:** Set `Status` in `.agent/TASK.md` to `PLANNING`; submit plan (services, ports, volumes, networks); await approval; then set to `RUNNING`.
3. **Falsifiable Definition of Done (DoD):**
   A task MUST NOT be marked done based on subjective appraisal. It MUST satisfy:
   - [ ] Syntax Validation: `docker compose config --quiet` exits with code 0.
   - [ ] Port Conflict Assertion: No port collisions with existing services or host.
   - [ ] Healthchecks & Limits: Every production service defines healthcheck and resource limits; HTTP services standardize on `/health` or `/healthz` with probe access log suppression.
   - [ ] Registry Invariants: `.agent/SERVICES.md` and `.env.example` synchronized.
   - [ ] Documentation Frontmatter: All docs under `docs/` MUST include YAML frontmatter (`author_type`, `author`, `reviewed_by`, `date`, `status`, `type`).
   - [ ] Git Cleanliness: `git diff --check` exits with code 0.
   - [ ] Documentation Perimeter: If exposed ports, `.env.example` variables, or service topology changed, synchronize `README.md` and `README.pt-br.md` (zero heading emojis, Mermaid diagrams, falsifiable metrics — see `readme-standard` skill).
   - [ ] Knowledge Preservation: Document obscure platform/runtime gotchas or workarounds as an atomic card in `.agent/knowledge/` (if applicable).
   - [ ] Atomic Commit: Conventional Commits in English (`feat(service): ...`).
   - [ ] Task Log: Active task logged in `TASK.md`; edge cases recorded in `NOTES.md`.

---

## Fail-Stop Protocol & Escalation Hierarchy

If an automated command (`docker compose config`, container boot, or healthcheck) fails **2 consecutive times** with the same root cause:
1. The agent MUST STOP execution immediately.
2. The agent MUST NOT attempt random environment alterations.
3. The agent MUST escalate to the user with a structured diagnostic block:
   ```yaml
   failure_stage: "compose_config | container_boot | healthcheck"
   error_signature: "exact error message or container exit code"
   consecutive_failures: 2
   root_cause_analysis: "port collision | mount permissions | invalid syntax"
   attempted_fixes:
     - "fix 1 description"
     - "fix 2 description"
   volume_data_state: "intact (no destructive operations performed)"
   pending_decision: "question or proposed options for user"
   ```
4. **Postmortem Trigger:** If an incident resulted in service downtime or required non-trivial architectural remediation, the agent MUST log a Tier 3 postmortem under `docs/incidents/YYYY-MM-DD-<slug>.md` and register the action items in `docs/incidents/README.md`.

---

## Task Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Subtasks: `[XX.Y.Z]`. Exactly **one** task active in `RUNNING` status. IDs are immutable within a release cycle. After Git tag: archive to `ARCHIVE.md`, restart at `[00.1]`/`[01.1]`, and update active task ID.

**Next ID:** Derived solely from Active Task + Log of current cycle. Ignore Future Backlog and closing sections. Same epic $\rightarrow$ `Y+1`. New epic $\rightarrow$ `[XX+1.1]`. Never jump to `90.x`/`99.x` unless performing refactoring/release explicitly requested by user.

**Release:** `[99.1]` is not a queue item. It becomes active only with explicit human instruction. Never trigger release tags autonomously; never treat `99.x` as an artificial ceiling.

| Prefix | Phase | Focus |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Topology | Ports, volumes, `SERVICES.md` |
| **`01.x`** | Foundation | Reverse proxy, SSL, networks, healthchecks |
| **`02.x`–`89.x`** | Services | New service stacks per domain |
| **`90.x`** | Optimization | Limits, base images, network tuning |
| **`99.x`** | Hardening | Port auditing, secrets scrubbing, backup verification, tag — human approval required |

---

## Post-Release Hygiene (Trigger: Git tag on any phase)

Not restricted to phase `99.x`. When releasing `vX.Y.Z`:

1. **Archive:** Move completed log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Record active topology in `SERVICES.md`; prune ephemeral scratch notes in `NOTES.md`.
3. **Perimeter:** Sync `.env.example`, `README.md`, `README.pt-br.md` (following `readme-standard`), and `compose.yaml` to the release tag.
4. **Reset:** Reset task numbering; correct active task ID; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

---

## Golden Rules

- **MUST NOT** hardcode secrets/tokens in YAML; use `${VAR}` + placeholders in local stack `.env.example`.
- **MUST NOT** store secrets in a global root `.env` when deploying modular stacks; isolate secrets per stack folder.
- **MUST NOT** execute `docker compose down -v`, `docker volume rm`, or `docker volume prune`.
- **MUST NOT** use the `:latest` image tag. Third-party infra MUST pin semantic tags or SHA digests (LTS). Satellite APPs on GHCR MUST pull from `${APP_VERSION:-main}`.
- **MUST NOT** start a production service without a `healthcheck` and CPU/memory limits.
- **MUST** standardize HTTP container healthchecks on `/health` or `/healthz` and discard/suppress successful probe access logs to prevent telemetry pollution (see `k-002`).
- **MUST NOT** change bind mounts without verifying existing data and host UID:GID permissions.
- **MUST NOT** expose administrative or database ports to `0.0.0.0` without strong auth or network isolation.
- **MUST NOT** add services to Compose without updating `.agent/SERVICES.md`.
- **Circuit breaker:** 2 consecutive failures with the same root cause $\rightarrow$ stop and ask the user.
- **MUST** document non-obvious orchestration constraints, dependency order requirements, kernel capabilities (`cap_add`), and network quirks as in-file comments using explicit invariant prefixes (e.g., `# INVARIANT: <rationale>`), explaining the architectural *why* rather than restating the YAML syntax.
- **MUST** write all agent-facing directives, service catalogs, skills, and task logs (`AGENTS.md`, `.agent/*`) in concise Technical English to optimize context token density and instruction compliance.

---

## Code Quality & Contrast Pairs

Declare clear boundaries and pinned images for all orchestrated containers.

### Contrast Pairs (DO / DON'T)

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

---

## Validation Commands

- Syntax verification: `docker compose config --quiet` (Exit code MUST be 0)
- Full configuration dump: `docker compose config`
- Port check: `ss -tuln | grep ":<PORT>"`
- Container lifecycle: `up -d <svc>`, `ps`, `logs --tail=100 -f <svc>`, `restart <svc>`

---

## Git Conventions

- **Atomic Commits:** Validate Compose syntax before committing.
- **Scrubbing:** **MUST NOT** commit `volumes/`, `data/`, or production `.env`.
- **Conventional Commits:** MUST follow `<type>(<scope>): <summary in English imperative>`.
  - `feat(service): add victorialogs with healthcheck and limits`
  - `fix(network): isolate redis to internal backend network`
- **Safety:** Push only upon explicit user request; **MUST NOT** force-push (`--force`) to primary branches. Homelab production deployments require human review.
