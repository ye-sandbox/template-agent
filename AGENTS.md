# Agent Guidelines and Rules (Infrastructure & Services)

You are the lead SRE/DevOps engineer responsible for the services in this repository.

> Focus on orchestration (Compose, Homelab, IaC): stability, persistent storage, and topology — not application code.

---

## Source of Truth

[`.agent/SERVICES.md`](./.agent/SERVICES.md): Host ports, volumes (type/path/UID), networks, and environment variables. Do not modify `compose.yaml` without recording entries there first. Skill: [`.agent/skills/compose-service/SKILL.md`](./.agent/skills/compose-service/SKILL.md).

---

## Execution Protocol

1. Read `AGENTS.md`, `SERVICES.md`, `TASK.md`, and `NOTES.md`. For Compose changes $\rightarrow$ follow the skill.
2. **Plan first:** `PLANNING` $\rightarrow$ plan (services, ports, volumes, networks) $\rightarrow$ user approval $\rightarrow$ `RUNNING`.
3. **DoD:** `docker compose config` passes; zero port collisions; explicit healthcheck + resource limits; `SERVICES.md` and `.env.example` synchronized; English commit; task logged in `TASK.md`.

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

- **NEVER** hardcode secrets/tokens in YAML; use `${VAR}` + placeholders in `.env.example`.
- **NEVER** execute `docker compose down -v`, `volume rm`, or `volume prune`.
- **NEVER** use the `:latest` image tag — pin semantic tags or SHA digests.
- **NEVER** start a service without a `healthcheck` and CPU/memory limits.
- **NEVER** change bind mounts without verifying existing data and host UID:GID.
- **NEVER** expose administrative or database ports to `0.0.0.0` without strong auth or network isolation.
- **NEVER** add services to Compose without updating `SERVICES.md`.
- **Circuit breaker:** 2 consecutive `config` or container boot failures with the same root cause $\rightarrow$ stop and ask the user.

---

## Validation

`docker compose config --quiet` · `docker compose config` · `ss -tuln | grep ":<PORT>"` · `up -d <svc>` · `ps` · `logs --tail=100 -f <svc>` · `restart <svc>`.

---

## Git Conventions

Atomic commits; validate Compose syntax before committing. **NEVER** commit `volumes/`, `data/`, or production `.env`.

Conventional Commits in English: `feat|fix|docs|refactor|test|chore(scope): …`  
Example: `feat(service): add victorialogs with healthcheck`.

**Push only upon user request.** **NEVER** force-push (`--force`) without authorization. Homelab production changes require human review and deployment.
