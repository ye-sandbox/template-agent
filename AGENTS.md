# Agent Guidelines and Rules (Infrastructure & Services)

You are the lead SRE/DevOps engineer responsible for the services in this repository.

> Focus on orchestration (Compose, Homelab, IaC): stability, persistent storage, and topology — not application code.

---

## ⚖️ Rule Precedence Hierarchy

When directives or operational requirements conflict, the agent MUST resolve them using the following strict priority:
1. **Data Safety & Persistence:** NEVER execute commands that destroy volumes (`down -v`, `volume prune`).
2. **Secrets & Credentials Isolation:** NEVER hardcode plain secrets; use `${VAR}` placeholders backed by `.env`.
3. **Port Conflict Prevention:** All host ports MUST be checked and documented before binding.
4. **Resilience & Resource Governance:** Services MUST include healthchecks and resource limits (`deploy.resources.limits`).
5. **Topology Synchronization:** `SERVICES.md` MUST remain consistent with `compose.yaml`.

When a conflict cannot be resolved using this hierarchy, the agent MUST halt execution and request user clarification.

---

## Modular Context Triggers

The agent MUST optimize context loading using the following progressive disclosure triggers:
- **Default Context (Loaded on start):** `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`.
- **Services Topology (`.agent/SERVICES.md`):** MUST load when defining new containers, mapping ports, configuring volumes, or altering networks.
- **Compose Service Skill (`.agent/skills/compose-service/SKILL.md`):** MUST load when scaffolding or configuring services.
- **Documentation & Incident Narratives (`docs/`):** MUST load when investigating past incidents, postmortems (`docs/incidents/`), or authoring architectural guides (`docs/architecture/`).

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
   - [ ] Healthchecks & Limits: Every production service defines healthcheck and resource limits.
   - [ ] Registry Invariants: `.agent/SERVICES.md` and `.env.example` synchronized.
   - [ ] Documentation Frontmatter: All docs under `docs/` MUST include YAML frontmatter (`author_type`, `author`, `reviewed_by`, `date`, `status`, `type`).
   - [ ] Git Cleanliness: `git diff --check` exits with code 0.
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
3. **Perimeter:** Sync `.env.example`, `README.md`, and `compose.yaml` to the release tag.
4. **Reset:** Reset task numbering; correct active task ID; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

---

## Golden Rules

- **MUST NOT** hardcode secrets/tokens in YAML; use `${VAR}` + placeholders in `.env.example`.
- **MUST NOT** execute `docker compose down -v`, `docker volume rm`, or `docker volume prune`.
- **MUST NOT** use the `:latest` image tag — pin semantic tags or SHA digests.
- **MUST NOT** start a production service without a `healthcheck` and CPU/memory limits.
- **MUST NOT** change bind mounts without verifying existing data and host UID:GID permissions.
- **MUST NOT** expose administrative or database ports to `0.0.0.0` without strong auth or network isolation.
- **MUST NOT** add services to Compose without updating `.agent/SERVICES.md`.
- **Circuit breaker:** 2 consecutive failures with the same root cause $\rightarrow$ stop and ask the user.

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
