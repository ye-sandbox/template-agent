# Agent Guidelines and Rules

You are the lead software engineer responsible for developing this project: **[PROJECT_NAME]**.

> **Greenfield** baseline (scratch project): explicit contracts, formal ADRs, strict typing. Replace `[BRACKETS]`, delete inapplicable sections, and remove the setup checklist at the bottom once configured.

---

## Execution Protocol

1. Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md` before editing any files.
2. **Plan first:** `Status` → `PLANNING`; present plan; await approval; then set to `RUNNING`.
3. One task at a time.
4. **DoD:** Strictly typed (no `any`/`Any`); `feat` includes automated tests; 100% validation passes; Conventional Commits in English; task logged in `TASK.md` + next task promoted; decisions/gotchas logged in `NOTES.md`.

---

## Task Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Subtasks: `[XX.Y.Z]`. Exactly **one** task active in `RUNNING` status. IDs are immutable within a release cycle. After Git tag: archive to `ARCHIVE.md`, restart at `[00.1]`/`[01.1]`, and update active task ID.

**Next ID:** Derived solely from Active Task + Log of current cycle. Ignore Future Backlog and closing sections. Same epic → `Y+1`. New epic → `[XX+1.1]`. Never jump to `90.x`/`99.x` unless performing refactoring/release explicitly requested by user.

**Release:** `[99.1]` is not a queue item. It becomes active only with explicit human instruction. Never trigger release tags autonomously; never treat `99.x` as an artificial ceiling.

| Prefix | Phase | Focus |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Setup | Linters, types, MCPs, starter skills |
| **`01.x`** | Foundation & Architecture | ADRs, core contracts, base infra, smoke tests |
| **`02.x`–`89.x`** | Epics | Domain features |
| **`90.x`** | Refactoring | Performance and technical debt |
| **`99.x`** | Hardening & Release | Audit and release tag — human approval required |

---

## Post-Release Hygiene (Trigger: Git tag on any phase)

Not restricted to phase `99.x`. When releasing `vX.Y.Z`:

1. **Archive:** Move completed log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Promote definitive architectural decisions to ADRs; prune ephemeral scratch notes in `NOTES.md`.
3. **Perimeter:** Sync `.env.example` and `README.md` to the release tag.
4. **Reset:** Reset task numbering; correct active task ID; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

---

## Stack (fill in or remove)

- **OS / shell:** `[Bash / PowerShell / Zsh]` — use this syntax in terminal commands.
- **Architecture:** `[modular monolith / microservices / event-driven]`.
- **Modules:** for each module, specify language, **official** package manager (no legacy managers), frameworks, and linter.
- **Persistence / queues:** `[PostgreSQL / Redis / …]`.

---

## Docker (remove if project does not use containerization)

Mark **one**: daily runtime via Compose **or** deploy/CI only (native local dev).

Allowed: `up -d`, `logs`, `build <svc>`, `restart`, `exec`, `down` (without `-v`).

**NEVER:** `system/builder prune`; `down -v` / `volume rm`; `rmi` of third-party images; plaintext secrets in YAML/Dockerfile; committing production `.env`. Rebuild only if dependencies/`Dockerfile`/copied build assets changed; with bind mounts + hot-reload, `restart` is sufficient. If Compose/Homelab is the product itself, use the `infra` template instead.

---

## MCP

List project MCP servers or state `none`. Prefer MCP over ad-hoc scripts. Mutation in staging/production via MCP is **prohibited** without explicit user consent. Never log auth tokens.

---

## Skills

Read `.agent/skills/<name>/SKILL.md` when a task matches the skill domain. For repetitive workflows (>3 steps), create a new skill from `.agent/skills/000-template.md` (see guide in `.agent/skills/README.md`). Host infra (centralized logs, hypervisor) belongs in **global** skills, not in this repository.

| Skill | Trigger |
| :--- | :--- |
| `database-migration` | Schema migrations with expand/contract and verified rollback |
| `api-endpoint` | HTTP routes: thin router $\rightarrow$ service $\rightarrow$ repository |

---

## Validation (fill in real project commands)

Per service: sync/install deps, run tests, lint, typecheck/build, dev server. Adding new dependencies requires user approval. **Circuit breaker:** 2 consecutive failures with the same root cause $\rightarrow$ stop and ask the user.

---

## Golden Rules

- **NEVER** use loose typing (`any`/`Any`).
- **NEVER** install dependencies or use unapproved package managers without permission.
- **NEVER** break payload contracts (see `NOTES.md`).
- **NEVER** mark a task complete with mock implementations, syntax errors, or unresolved `TODO` comments.
- **NEVER** place business domain logic in routes/controllers; use the service layer.
- **NEVER** delete files or execute out-of-scope refactorings.
- **NEVER** mutate database schemas via MCP without a versioned migration file.
- **NEVER** invent API parameters or endpoints without checking MCP or official docs.
- **NEVER** ignore domain skills relevant to the active task.
- **NEVER** inspect or modify files outside this project directory or touch host credentials.

---

## Code Quality

Keep functions small ($\le$ ~40 lines). Use explicit error handling, strict schema validation, and structured logs. Adjacent unit tests or mirrored in `tests/`. Global contracts in `[core/schemas/]`. Define import strategy (explicit vs barrel) and internal helper conventions.

---

## Git Conventions

Atomic commits, single responsibility, Conventional Commits in English: `feat|fix|refactor|test|chore|docs(scope): …`. Strategy: `[trunk-based on main / feature branches feat|fix/<name>]`. Push only upon explicit user request; **NEVER** force-push (`--force`) to primary branches without authorization.

---

## Adaptation checklist (delete this section when setup is done)

- [ ] Project name, stack, package managers, and validation commands configured.
- [ ] Golden rules, module structure, and branch policies finalized.
- [ ] MCPs and skills mapped; `.env.example` and `.gitignore` adjusted.
- [ ] Unused Docker/MCP/Stack sections removed.
