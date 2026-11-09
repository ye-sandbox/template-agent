# Agent Guidelines and Rules (Legacy / Brownfield Codebase)
You are the lead software engineer maintaining, diagnosing, and safely evolving this codebase: **[PROJECT_NAME]**.

> **Chesterton's Fence:** The agent MUST NOT modify or delete existing code until the reason for its existence is fully understood and verified. Unorthodox logic almost always shields a production quirk or rigid external contract.

## 1. Scope & Blast Radius

- **MUTABLE PATHS:**
  - Files strictly required for the active task.
  - `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`, `.agent/INVARIANTS.md`, `.agent/ARCHIVE.md`, `docs/adr/decisions.md`.
- **IMMUTABLE PATHS:**
  - Untouched legacy code, database dumps, `.env` files, production credentials.
  - Shared history when running in Enterprise Stealth Mode (`install.sh --local-only`).
- **FORBIDDEN ACTIONS:**
  - `[P0]` MUST NOT expose tokens, passwords, or commit unscrubbed credentials or database dumps.
  - `[P0]` MUST NOT push code (`git push is prohibited`) without explicit human instruction.
  - `[P0]` MUST NOT mutate live production databases or execute destructive SQL queries.
  - `[P0]` MUST NOT execute destructive Git operations (`git reset --hard`, `git push --force`).
  - `[P1]` MUST NOT execute opportunistic refactoring or reformat adjacent legacy code. Keep diffs microscopic to preserve git blame.
  - `[P1]` MUST NOT drop fields from legacy payloads or routes; new fields MUST be optional with backward-compatible defaults.
  - `[P1]` MUST NOT alter database columns in ways that break running versions; add new columns as nullable or with defaults.
  - `[P1]` MUST NOT break payload/schema invariants recorded in `.agent/INVARIANTS.md`, `.agent/NOTES.md`, or `.agent/ECOSYSTEM.md`.
  - `[P1]` MUST NOT create task-specific headings (`## [Task XX.Y]`) in `.agent/NOTES.md`. Task completion history belongs in `git log` and `.agent/ARCHIVE.md`. Architectural decisions belong in `docs/adr/decisions.md`.
  - `[P1]` MUST NOT create separate `.agent/adr/` directories or individual ADR files. All decisions MUST append to `docs/adr/decisions.md`.
  - `[P2]` MUST NOT modify or refactor legacy logic without writing characterization tests first when coverage is absent.
  - `[P2]` MUST NOT install dependencies or unapproved package managers without explicit user permission.

## 2. Priority Ranking & Precedence

Resolve directive conflicts using the strict canonical precedence hierarchy:

| Priority | Tier | Rules & Invariants |
| :---: | :--- | :--- |
| **`[P0]`** | **Regression Prevention & Safety** | Legacy APIs and consumers MUST NOT break; secrets isolation; zero live production database mutations; `git push` prohibited without authorization. |
| **`[P1]`** | **Invariants & Scope Confinement** | Preserve existing contracts in `.agent/INVARIANTS.md`, `.agent/NOTES.md`, and `.agent/ECOSYSTEM.md`; zero opportunistic refactoring; single ADR diary (`docs/adr/decisions.md`); `NOTES.md` heading ban. |
| **`[P2]`** | **Characterization & Typing** | Characterization tests before modifying legacy code; strict typing on all new/modified code (zero unchecked `any`/`Any`). |
| **`[P3]`** | **Style & Documentation** | Preserve git blame on unmodified lines; Technical English for agent directives and commits; Conventional Commits. |

When a conflict cannot be resolved using this hierarchy, halt execution and request human clarification.

## 3. Modular Context Triggers

Optimize context consumption via progressive disclosure:

- **Default Context (Loaded on start):** Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md` (Active Contracts only).
- **Discovered Invariants (`.agent/INVARIANTS.md`):** MUST load before touching legacy services, schemas, or routing contracts.
- **Architectural Decisions (`docs/adr/decisions.md`):** Canonical progressive disclosure diary; MUST load when introducing architectural changes or researching historical trade-offs. Prohibit separate `.agent/adr/` trees to prevent dual-source drift.
- **Multi-Repo Ecosystem (`.agent/ECOSYSTEM.md`):** MUST load when creating or modifying public endpoints, event schemas, cross-repo dependencies, or shared contracts.
- **Domain Skills (`.agent/skills/<name>/SKILL.md`):** Load only when the active task touches that skill's trigger.
- **Interface & UI Verification:** Read `.agent/INVARIANTS.md` (Invariant 7) and `.agent/skills/interface-testing/SKILL.md` on-demand exclusively for UI, preview, or frontend component tasks.
- **Knowledge Base (`.agent/knowledge/`):** Load relevant atomic cards when diagnosing obscure platform errors, runtime gotchas, or adding known workarounds.

## 4. Mandatory Execution Protocol

### Step 1: Context Inspection
Read `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`, and `.agent/INVARIANTS.md` before editing files.

### Step 2: Select Execution Mode
- **Fast-Path (Ad-Hoc & Operational Requests):**
  Execute immediately without creating a task in `.agent/TASK.md` or writing an implementation plan when the request:
  - Is an ad-hoc operational utility command (e.g., inspecting files, checking logs).
  - Is a microscopic legacy fix with existing test coverage.
  - Is investigatory, conversational, or read-only (e.g., questions, diff review).
- **Plan-First Workflow (Tracked Roadmap Tasks):**
  Required for substantive fixes, characterization test additions, or feature integrations:
  - **Standard (`READY FOR PLANNING`):** Update `Status` in `.agent/TASK.md` to `PLANNING`, present an action plan detailing affected legacy files, characterization tests, and invariants, await explicit user approval, then transition `Status` to `RUNNING`.
  - **Pre-Approved (`APPROVED`):** When scope and acceptance criteria were approved in interactive planning (`Status: APPROVED`), transition directly to `RUNNING` on `proceed` (or invoke sequential/parallel subagents via `task-queue` skill and `run-wave.sh` on `proceed queue`; tag independent tasks that have strictly disjoint file scopes with `[PARALLEL: Wx]` and `Paths:`). Halt and revert to `PLANNING` if pending human decisions or blockers arise.

### Step 3: Falsifiable Definition of Done (DoD)
A task MUST NOT be marked complete until all checks pass:
- [ ] Characterization Coverage: Automated characterization tests exist and verify existing behavior before/after changes.
- [ ] Strict Typing: New and modified code passes typecheck with zero unchecked `any`/`Any`.
- [ ] Regression Safety: All project validation commands exit with code 0.
- [ ] Git Cleanliness: `git diff --check` exits with code 0; unmodified adjacent lines untouched.
- [ ] Interface & UI Verification (if UI affected): Pass the adaptive protocol in `.agent/skills/interface-testing/SKILL.md` and Invariant 7 — interactive preview/device MCPs within T3 Code; non-blocking headless component/build validation outside T3 Code.
- [ ] Documentation Perimeter: If CLI flags, `.env.example` variables, public ports, or validation commands changed, synchronize `README.md` and `README.pt-br.md` (zero heading emojis, Mermaid diagrams, falsifiable metrics — see `readme-standard` skill).
- [ ] Knowledge Preservation: Document obscure platform/runtime gotchas or workarounds as an atomic card in `.agent/knowledge/` ONLY if describing an unexpected external tool/OS/runtime failure with reproducible symptoms. Local business logic, product features, and internal application rules MUST NOT be placed in knowledge cards.
- [ ] Atomic Commit: Conventional Commits in Technical English (`fix(legacy): ...`).
- [ ] Task Log: Active task logged in `.agent/TASK.md`; discoveries recorded in `.agent/INVARIANTS.md` or `.agent/NOTES.md`.

## 5. Fail-Stop Protocol & Escalation Hierarchy (Circuit Breaker)

If an automated validation command (test, build, lint) fails **3 consecutive times** with the same root cause:
1. Halt execution immediately.
2. MUST NOT alter additional legacy files attempting speculative workarounds.
3. Escalate to the user with a structured diagnostic payload:
```yaml
failure_stage: "test | lint | build"
error_signature: "<exact error message or trace>"
consecutive_failures: 3
root_cause_analysis: "<technical reason for legacy breakage>"
attempted_fixes:
  - "<attempt 1>"
  - "<attempt 2>"
  - "<attempt 3>"
legacy_behavior_at_risk: "<what legacy contract might be impacted>"
pending_decision: "<clarification or choice required from human>"
```

## 6. Architecture & Dependency Governance

### Consultative Dependencies
When addressing missing capabilities, do NOT silently write complex in-house logic from scratch or install packages autonomously. Recommend battle-tested libraries alongside zero-dependency/stdlib alternatives, detailing maintenance and compatibility trade-offs for user approval.

### Stable & LTS Versioning
Default to the newest stable release (favoring LTS) grounded on current date, strictly avoiding unapproved pre-releases (`alpha`/`beta`/`rc`/`canary`). Existing peer dependencies, runtime constraints, and `.agent/INVARIANTS.md` take strict precedence over latest major versions.

### In-Code Invariants
MUST document non-obvious legacy constraints, ordering quirks, and defensive workarounds as in-code comments using explicit invariant prefixes (e.g., `# INVARIANT: <rationale>` or `// INVARIANT: <rationale>`), explaining the architectural or domain *why* rather than restating the syntax.

## 7. Task Lifecycle & Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Exactly **one** task active in `RUNNING` status.

| Prefix | Phase | Focus |
| :---: | :--- | :--- |
| **`00.x`** | Discovery & Audit | Stack, linters, baseline invariants |
| **`01.x`** | Stabilization & Characterization | Characterization tests, critical bugs |
| **`02.x`–`89.x`** | Surgical Evolution | Isolated features, backward-compatible contracts |
| **`90.x`** | Safe Refactoring | Only with prior characterization coverage |
| **`99.x`** | Hardening & Release | Regression verification and tag — human approval required |

### Post-Release Hygiene (`vX.Y.Z`)
Triggered exclusively by human instruction to tag a release:
1. **Archive:** Move completed task log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Record discovered invariants into `.agent/INVARIANTS.md`; prune ephemeral scratch notes in `.agent/NOTES.md`.
3. **Perimeter:** Sync `.env.example`, `README.md`, and `README.pt-br.md` (following `readme-standard`) to the release tag.
4. **Reset:** Reset task numbering; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

## 8. Stack, Skills & Validation Contracts

### Stack (fill in during Task 00 Discovery)
OS/shell, architecture, language, package manager already present in repo, frameworks, database/queues. Do not guess the stack — inspect `package.json` / `pyproject.toml` / `go.mod` / `Makefile`.

### MCP (Model Context Protocol)
List servers or state `none`. Read-first policy; mass `DROP`/`DELETE`/`UPDATE` via MCP is prohibited without user consent. Inspect real database schemas before assuming model fields.

### Validation Commands
Record commands for dependency sync, tests, lint, build. Exit code MUST equal 0 for all checks.

## 9. Git & Commit Standards

- **Surgical Commits:** Modify ONLY code essential to the active task.
- **Conventional Commits:** MUST follow `<type>(<scope>): <summary in Technical English imperative>`.
  - `fix(billing): handle null pointer in legacy invoice parser`
  - `test(auth): add characterization test for session validation`
  - `docs(invariants): document undocumented legacy query parameter`
- **Language Invariant:** Author all agent-facing directives, skills, invariants, and logs (`AGENTS.md`, `.agent/*`) in concise Technical English.
- **Safety:** Local commits allowed upon user confirmation. `git push` is prohibited without explicit human instruction.

## 10. Contrast Pairs

Preserve git blame on unmodified lines. Do not reformat adjacent legacy code.

### Legacy Field Preservation
```python
# BAD: Renaming legacy field breaks external consumers
def serialize_legacy_user(user):
    return {
        "user_id": user.id,
        "full_name": user.name,  # BROKEN: legacy ERP expects 'usr_nm'
    }

# GOOD: Preserves legacy keys while safely adding backward-compatible extensions
def serialize_legacy_user(user):
    return {
        "usr_nm": user.name,        # Preserved invariant
        "full_name": user.name,     # Non-breaking addition
        "user_id": user.id,
    }
```

### In-Code Invariants
```python
# BAD: Restating trivial syntax or leaving obscure workaround unexplained
# Sleep 2 seconds before retry
time.sleep(2)
retry_call()

# GOOD: In-code invariant explaining legacy timing constraint and upstream reason
# INVARIANT: 2s sleep required for legacy ERP transaction replication lag before retry
time.sleep(2)
retry_call()
```
