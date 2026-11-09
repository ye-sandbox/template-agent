# Agent Guidelines and Rules — Template Hub Repository

Central governance specification for maintaining and evolving the Agent-Driven Development (ADD) Template Hub.

## 1. Scope & Blast Radius

- **MUTABLE PATHS:**
  - `AGENTS.md`
  - `.agent/TASK.md`, `.agent/NOTES.md`, `.agent/ARCHIVE.md`, `.agent/INVARIANTS.md`
  - `.agent/skills/**`
  - `docs/**`, `README.md`, `README.pt-br.md`, `CHANGELOG.md`
  - `.github/workflows/**`, `.github/scripts/**`
- **IMMUTABLE PATHS:**
  - Specialized starter files on `main` (starter filetrees belong exclusively to their respective branches: `greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`).
  - `.env` files, credentials, private tokens.
- **FORBIDDEN ACTIONS:**
  - `[P0]` MUST NOT execute `git merge` between specialized branches (`main`, `greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`).
  - `[P0]` MUST NOT execute destructive Git operations (`git push --force`, `git reset --hard`, `git clean -fd`) without explicit human instruction.
  - `[P0]` MUST NOT commit unscrubbed credentials, API keys, or private tokens.
  - `[P1]` MUST NOT create task-specific headings (`## [Task XX.Y]`) in `.agent/NOTES.md`. Task completion history belongs in `git log` and `.agent/ARCHIVE.md`. Architectural decisions belong in `docs/adr/decisions.md`.
  - `[P1]` MUST NOT create separate `.agent/adr/` directories or individual ADR files. All decisions MUST append to `docs/adr/decisions.md`.
  - `[P1]` MUST NOT break backward compatibility of `install.sh` or `init.sh`.
- **EXCEPTIONS:**
  - Cross-branch synchronization permitted exclusively via atomic cherry-picking or selective file checkout (`git checkout <source-branch> -- <file>`).

## 2. Priority Ranking & Precedence

Resolve directive conflicts using the strict canonical precedence hierarchy:

| Priority | Tier | Rules & Invariants |
| :---: | :--- | :--- |
| **`[P0]`** | **Security & Blast Radius** | Branch isolation (zero cross-branch merges), destructive git command ban, credential scrubbing. |
| **`[P1]`** | **Invariants & Automated Contracts** | Single ADR diary (`docs/adr/decisions.md`), `NOTES.md` heading ban, automated CI checks, falsifiable DoD assertions. |
| **`[P2]`** | **Execution & Test Harness** | Plan-First protocol, task numbering format (`[XX.Y]`), Conventional Commits, single active task in `RUNNING`, adaptive UI verification protocol (T3 preview/device MCPs vs. headless builds/tests). |
| **`[P3]`** | **Style & Documentation** | Markdown link validity, Technical English for agent contracts, localized human READMEs. |

When a conflict cannot be resolved using this hierarchy, halt execution and request human clarification.

## 3. Repository Branch Map

Starters exist as isolated roots on specialized branches. NEVER merge across branches.

| Branch | Role | Root Contents / Purpose |
| :--- | :--- | :--- |
| **`main`** | Hub Governance | Documentation hub, decision matrix, governance rules, and inter-branch CI scripts. |
| **`greenfield`** | Scratch Starter | Clean starter kit (`docs/adr/decisions.md`, `.agent/skills/`). |
| **`brownfield`** | Legacy Adoption | Injection kit (`install.sh`, `.agent/INVARIANTS.md`, `.agent/ECOSYSTEM.md`, Task 00 Discovery). |
| **`blackbox`** | Reverse Engineering | Automations, scrapers, closed APIs (`.agent/ENDPOINTS.md`, `.agent/skills/reverse-engineering/`, `init.sh`). |
| **`infra`** | Service Orchestration | Docker Compose, homelab (`.agent/SERVICES.md`, `.agent/skills/compose-service/`, `compose.yaml.example`, `init.sh`). |
| **`baremetal`** | Workstation & OS Tuning | Host tuning, kernel/sysctl tweaks, dotfiles (`.agent/BASELINE.md`, `.agent/INVARIANTS.md`, `.agent/TUNINGS.md`, `init.sh`). |

## 4. Modular Context Triggers

Optimize context consumption via progressive disclosure:

- **Default Context (Loaded on start):** Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md` (Active Contracts only).
- **On-Demand Context (Progressive Disclosure):**
  - Architectural decisions: Read `docs/adr/decisions.md`. Prohibit separate `.agent/adr/` trees to prevent dual-source drift.
  - Multi-repo topology: Read `.agent/ECOSYSTEM.md`.
  - Platform/runtime gotchas: Read `.agent/knowledge/<card>.md`.
  - Interface & UI verification: Read `.agent/skills/interface-testing/SKILL.md` (loaded on-demand exclusively for UI, preview, or frontend component tasks).
  - System invariants & rigid legacy contracts: Read `.agent/INVARIANTS.md`.
- **Branch-Specific Context:** Checkout the target branch BEFORE inspecting its root files.
- **Transversal Skills:** Reference external organizational playbooks (`agent-skills`) ONLY when tasks require UI porting, QA audit, task-queue wave execution, or host-level orchestration.

## 5. Mandatory Execution Protocol

### Step 1: Context Inspection
Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md` before editing files on `main`. Checkout the corresponding branch for starter-specific workflows.

### Step 2: Select Execution Mode
- **Fast-Path (Ad-Hoc & Operational Requests):**
  Execute immediately without creating a task in `.agent/TASK.md` or writing an implementation plan when the request:
  - Is an ad-hoc operational utility command (e.g., copying files, quick CLI inspection).
  - Is a trivial adjustment (e.g., fixing a typo, formatting, renaming a variable).
  - Is investigatory, conversational, or read-only (e.g., questions, diff review, log checks).
- **Plan-First Workflow (Tracked Roadmap Tasks):**
  Required for substantive architectural, feature, multi-file, or template changes:
  - **Standard (`READY FOR PLANNING`):** Update `Status` in `.agent/TASK.md` to `PLANNING`, present an action plan detailing affected branches and files, await explicit user approval, then transition `Status` to `RUNNING`.
  - **Pre-Approved (`APPROVED`):** When scope and acceptance criteria were approved in interactive planning (`Status: APPROVED`), transition directly to `RUNNING` on `proceed` (or invoke sequential/parallel subagents via `task-queue` skill and `run-wave.sh` on `proceed queue`). Halt and revert to `PLANNING` if pending human decisions or blockers arise.

### Step 3: Falsifiable Definition of Done (DoD)
Tasks MUST NOT be marked complete until all checks pass:
- [ ] Automated git check passes: `git diff --check` exits with code 0.
- [ ] Markdown relative links and branch targets validate without broken references.
- [ ] Atomic Conventional Commits in English (`feat(hub): ...`, `docs(task): ...`).
- [ ] Interface & UI verification (if UI affected): passes adaptive protocol (interactive preview/device MCPs within T3 Code; non-blocking headless component/build validation outside T3 Code).
- [ ] Knowledge preservation: Document obscure platform/runtime gotchas in `.agent/knowledge/` ONLY if describing an unexpected external tool/OS/runtime failure with reproducible symptoms. MUST NOT record application business logic or features in knowledge cards.
- [ ] Completed task logged as a single line in `.agent/TASK.md` and next task promoted.

## 6. Fail-Stop Protocol & Escalation Hierarchy

If an automated command or build step fails **3 consecutive times** with the same root cause:
1. Halt execution immediately.
2. MUST NOT attempt unapproved workarounds.
3. Escalate to the user with a structured diagnostic payload:
```yaml
failure_stage: "<command or step name>"
error_signature: "<exact error string>"
consecutive_failures: 3
root_cause_analysis: "<technical root cause>"
attempted_fixes:
  - "<attempt 1>"
  - "<attempt 2>"
  - "<attempt 3>"
pending_decision: "<clarification or choice required from human>"
```

## 7. Task Lifecycle & Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Subtasks: `[XX.Y.Z]`. Exactly **one** task active in `RUNNING` status. Derive next ID exclusively from active task + completed log.

| Prefix | Phase | Hub Scope |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Discovery | Initial setup, linters, baseline audit. |
| **`01.x`** | Foundation & Guardrails | Critical fixes, CI, canonical contracts, governance. |
| **`02.x`–`89.x`** | Epics | New templates, hub features (each decade = one epic). |
| **`90.x`** | Refactoring | Technical debt and performance optimization without contract changes. |
| **`99.x`** | Hardening & Release | Final audit and release tagging — human instruction REQUIRED. |

### Post-Release Hygiene (`vX.Y.Z`)
Triggered exclusively by human instruction to tag a release:
1. **Archive:** Move completed task log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Promote definitive architectural decisions to `docs/adr/decisions.md`; prune scratch notes from `.agent/NOTES.md`.
3. **Perimeter:** Sync `.env.example` and `README.md` to the release tag.
4. **Reset:** Reset task numbering; promote next milestone to `READY FOR PLANNING`; restore closing checklist.

## 8. Inter-Branch Synchronization Protocol

Branch root trees are intentionally disjoint. NEVER run `git merge` between specialized branches.

### 1. Atomic Commit Cherry-Picking
Propagate generic improvements across template branches:
```bash
git checkout <target-branch>
git cherry-pick <commit-hash>
```

### 2. Selective File Checkout
Propagate shared canonical files (e.g., `.gitignore`, `.env.example`):
```bash
git checkout <target-branch>
git checkout <source-branch> -- path/to/file
git commit -m "chore(sync): sync <file> from <source-branch>"
```

### 3. Responsibility Matrix
- `.github/workflows/ci.yml`: Centrally maintained on `main`.
- `.gitignore` and `.env.example`: Synchronized across all branches.
- `.agent/TASK.md` and `.agent/NOTES.md`: Maintained as live state on `main`; kept as clean canonical starter templates on other branches.

## 9. Git & Commit Standards

- **Atomic Commits:** Each commit MUST represent a single, verifiable change. NEVER mix governance, documentation, and script edits.
- **Conventional Commits:** All commit messages MUST follow `<type>(<scope>): <imperative summary>` in Technical English.
- **Subject Artifact Focus:** The subject line MUST describe the concrete change to repository files/artifacts. NEVER leak agent orchestration metadata or queue scheduling jargon into the subject (e.g., do NOT write `docs(task): queue wave W13 tasks [10.11]-[10.15] for execution`; DO write `docs(task): add micro-contracts for tasks [10.11]-[10.15]`).
- **Commit Body Requirement:** Commits introducing batches of tasks (`docs(task)`), architectural decisions, or non-trivial multi-file changes MUST include an explanatory body (separated by an empty line) summarizing the affected tasks, scope, or rationale. Never rely exclusively on a one-line subject for complex multi-task operations.
- **Language Invariant:** Author all agent-facing directives, contracts, skills, and logs (`AGENTS.md`, `.agent/*`) in Technical English. Human-facing documentation (`README.pt-br.md`) MAY be localized.

| Type | Purpose | Hub Scope Example |
| :---: | :--- | :--- |
| **`feat`** | New capability or starter branch | `feat(hub): add infra template branch to matrix` |
| **`fix`** | Bug fix in scripts or workflows | `fix(installer): resolve remote execution flag parsing` |
| **`docs`** | Documentation or task log updates | `docs(task): log task 01.6 completion` |
| **`refactor`** | Code or structure cleanup without behavior change | `refactor(ci): streamline multi-branch matrix testing` |
| **`test`** | Automated tests or contract assertions | `test(infra): add scaffolding verification step` |
| **`chore`** | Maintenance, inter-branch sync, or configs | `chore(sync): sync .gitignore from greenfield` |

## 10. Contrast Pairs

### Commit Messages
```markdown
// BAD: Combining multiple concerns, vague or past-tense message
git commit -m "fixed stuff, updated docs and updated init.sh"

// BAD: Leaking agent queue orchestration jargon into subject with no body
git commit -m "docs(task): queue wave W13 tasks [10.11]-[10.15] for execution"

// GOOD: Single atomic change with RFC-compliant imperative verb
git commit -m "fix(installer): resolve remote execution flag parsing"

// GOOD: Artifact-focused subject with structured body detailing batched tasks
git commit -m "docs(task): add micro-contracts for tasks [10.11]-[10.15]" -m "Queue parallel wave W13 in .agent/TASK.md:
- [10.11]: Bootstrap SQLite schema & cooldown monotonicity
- [10.12]: Update default API_PROXY_TARGET fallback
- [10.13]: Synchronize .env.example with gatekeeper-ts variables
- [10.14]: Align NOTES.md and migration blueprint
- [10.15]: Synchronize README perimeter for cycle v0.5.0"
```

### Inter-Branch Synchronization
```bash
# BAD: Merging branches pollutes clean template root
git checkout greenfield
git merge main

# GOOD: Selectively cherry-pick or checkout individual files
git checkout greenfield
git cherry-pick 88eddd8
```

### Task Lifecycle Progression
```markdown
// BAD: Silently executing substantive architectural changes without plan approval
[01.6] Status: READY FOR PLANNING -> Directly edited 10 files without plan approval

// GOOD: Standard Plan-First progression
[01.6] Status: READY FOR PLANNING -> Status: PLANNING (present plan) -> Human Approval -> Status: RUNNING
```

### Interface & UI Verification
```markdown
// BAD: Blindly attempting to launch preview browser tabs during headless CI or static web research
preview_open("http://localhost:3000") // when running outside T3 Code, during headless CI, or for static docs search

// GOOD: Adaptive interface testing matching runtime capabilities
# Inside T3 Code (interactive MCP runtime):
preview_status -> preview_open -> preview_snapshot -> preview_act -> preview_close
# Outside T3 Code (headless CLI runtime):
npm run build && npm test (or headless playwright/vitest without opening graphical display)
```
