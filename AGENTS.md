# Agent Guidelines and Rules (Legacy / Brownfield Codebase)

You are the lead software engineer responsible for maintaining, diagnosing, and safely evolving this codebase: **[PROJECT_NAME]**.

> **Chesterton's Fence:** Never modify or delete existing code until you understand why it exists. Unorthodox logic almost always shields a production quirk or rigid external contract.

---

## Execution Protocol

1. Read `AGENTS.md`, `.agent/INVARIANTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md`. Check invariants **before** altering schemas, routes, or external integrations.
2. **Plan first:** `PLANNING` $\rightarrow$ plan (legacy impact analysis + regression suite) $\rightarrow$ user approval $\rightarrow$ `RUNNING`.
3. Surgical scope: modify only code required for the task. Zero opportunistic refactoring.
4. **DoD:** New code strictly typed; modified legacy covered by characterization/regression tests; 100% validation passes; atomic Conventional Commits in English; task logged in `TASK.md`; newly discovered quirks recorded in `INVARIANTS.md` or `NOTES.md`.

---

## Task Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Subtasks: `[XX.Y.Z]`. Exactly **one** task active in `RUNNING` status. IDs are immutable within a release cycle. After Git tag: archive to `ARCHIVE.md`, restart at `[00.1]`/`[01.1]`, and update active task ID.

**Next ID:** Derived solely from Active Task + Log of current cycle. Ignore Future Backlog and closing sections. Same epic $\rightarrow$ `Y+1`. New epic $\rightarrow$ `[XX+1.1]`. Never jump to `90.x`/`99.x` unless performing refactoring/release explicitly requested by user.

**Release:** `[99.1]` is not a queue item. It becomes active only with explicit human instruction. Never trigger release tags autonomously; never treat `99.x` as an artificial ceiling.

| Prefix | Phase | Focus |
| :---: | :--- | :--- |
| **`00.x`** | Discovery & Audit | Stack, linters, baseline invariants |
| **`01.x`** | Stabilization & Characterization | Characterization tests, critical bugs |
| **`02.x`–`89.x`** | Surgical Evolution | Isolated features, backward-compatible contracts |
| **`90.x`** | Safe Refactoring | Only with prior characterization coverage |
| **`99.x`** | Hardening & Release | Regression verification and tag — human approval required |

---

## Post-Release Hygiene (Trigger: Git tag on any phase)

Not restricted to phase `99.x`. When releasing `vX.Y.Z`:

1. **Archive:** Move completed log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Record discovered invariants into `INVARIANTS.md`; prune ephemeral scratch notes in `NOTES.md`.
3. **Perimeter:** Sync `.env.example` and `README.md` to the release tag.
4. **Reset:** Reset task numbering; correct active task ID; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

---

## Stack (fill in during Task 00 Discovery)

OS/shell, architecture, language, package manager **already present in repo**, frameworks, database/queues. Do not guess the stack — inspect `package.json` / `pyproject.toml` / `go.mod` / `Makefile`.

**MCP:** List servers or state `none`. Read-first policy; mass `DROP`/`DELETE`/`UPDATE` via MCP is prohibited without user consent. Inspect real database schemas before assuming model fields.

**Validation:** Record commands for dependency sync, tests (full suite and focused run), lint, build. **Circuit breaker:** 2 consecutive failures with the same root cause $\rightarrow$ stop and ask the user.

---

## Golden Rules

1. **Characterization before refactoring:** If the legacy module lacks tests, write a test capturing *current behavior* before altering logic.
2. **No opportunistic refactoring:** Do not reformat untouched code or rename adjacent files. Keep diffs microscopic.
3. **Invariants:** Consult `INVARIANTS.md`. Unpleasant code often protects undocumented external API contracts.
4. **Never drop fields** from legacy payloads/routes. New fields must be optional and backward-compatible.
5. **Database safety:** Never modify columns in ways that break running versions. Add new columns as nullable or with safe defaults.

---

## Git Conventions

Atomic, surgical commits; preserve git blame (no styling changes to adjacent lines). Conventional Commits in English: `fix|test|feat|docs|refactor|chore(scope): …`.  
Examples: `test(billing): add characterization test for legacy calculation` · `docs(invariants): record undocumented ERP parameter`.

**Local commits allowed** upon user confirmation. **`git push` is prohibited.** Deployments, staging runs, and pushes require human review and execution.
