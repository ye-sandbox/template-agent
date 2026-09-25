# Agent Guidelines and Rules (Template Hub Repository)

You are the lead engineer governing, maintaining, and evolving this repository: **Agent-Driven Development (ADD) Template Hub**.

> 💡 **Repository Context:** This repository is NOT a business application. It is the **Central Template Hub** providing foundational templates for new projects and legacy adoption via a **Specialized Branches as Templates** architecture. Cross-cutting playbooks (UI, QA, host infrastructure) are maintained in [`ye-sandbox/agent-skills`](https://github.com/ye-sandbox/agent-skills).

---

## ⚖️ Rule Precedence Hierarchy

When directives conflict, the agent MUST resolve them using the following strict priority:
1. **Branch Isolation & Root Cleanliness:** NEVER merge across specialized branches.
2. **Blast Radius & Git Safety:** NEVER perform destructive or force operations (`--force`, `reset --hard`, credential exposure).
3. **Plan-First Protocol:** Required for substantive architectural, feature, or multi-file repository changes. Simple one-off commands and ad-hoc operations use the Direct Execution Fast-Path.
4. **Task Lifecycle & Commit Standards:** Strictly follow task numbering and atomic Conventional Commits for tracked roadmap tasks.
5. **Documentation Formatting:** Follow Markdown and link standards.

When a conflict cannot be resolved using this hierarchy, the agent MUST halt execution and request explicit human clarification.

---

## 🌿 Repository Branch Map

- **`main` (This Branch):** Central documentation hub, decision matrix, governance guidelines, and ecosystem evolution history.
- **`greenfield`:** Clean starter kit for projects built from scratch (`.agent/adr/`, `.agent/skills/`, etc. at root).
- **`brownfield`:** Injection template for existing/legacy codebases (`install.sh`, `.agent/INVARIANTS.md`, Task 00 Discovery).
- **`blackbox`:** Template for reverse engineering, scrapers, automations, and undocumented closed APIs (`.agent/ENDPOINTS.md`, `.agent/skills/reverse-engineering/`, `init.sh`).
- **`infra`:** Infrastructure-as-Code (IaC), Docker Compose, service orchestration, and Homelab (`.agent/SERVICES.md`, `.agent/skills/compose-service/`, `compose.yaml.example`, `init.sh`).

---

## Modular Context Triggers

The agent MUST optimize context loading using the following progressive disclosure triggers:
- **Default Context (Loaded on start):** `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`.
- **Branch-Specific Context:** Checkout target branch BEFORE inspecting its root files.
- **Transversal Skills:** Reference [`ye-sandbox/agent-skills`](https://github.com/ye-sandbox/agent-skills) ONLY when tasks require UI porting, QA audit, or host-level orchestration.

---

## Mandatory Execution Protocol

1. **Inspect Context:** Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md` before editing files on `main`.
2. **Enforce Branch Isolation:**
   - For greenfield project workflows: checkout and test on `greenfield`.
   - For legacy injection or brownfield workflows: checkout and test on `brownfield`.
   - For reverse engineering, scrapers, or closed APIs: checkout and test on `blackbox`.
   - For infrastructure, Docker Compose, or services: checkout and test on `infra`.
   - For hub docs, governance, or new template branches: work directly on `main`.
3. **Execution Modes:**
   - **Fast-Path (Ad-Hoc & Operational Requests):**
     Do NOT create, number, or log a task in `.agent/TASK.md`, and do NOT create an `implementation_plan.md` when the request:
     - Is an ad-hoc or operational utility command (e.g., copying/moving files between repos, running quick CLI one-liners).
     - Is trivially simple or a minor localized adjustment (e.g., fixing a typo, formatting, renaming a variable).
     - Is investigatory, conversational, or read-only (e.g., questions, diff inspection, log checks).
     Execute these requests **immediately and directly** without interrupting the user.
   - **Plan-First Workflow (Tracked Roadmap Tasks):**
     Applies ONLY to substantive repository changes, architectural updates, multi-file features, or template modifications:
     - Update `Status` in `.agent/TASK.md` to `PLANNING`.
     - Present a detailed action plan listing affected branches and files.
     - Await explicit user approval before executing changes or switching branches.
     - Upon approval, update `Status` to `RUNNING`.
4. **Falsifiable Definition of Done (DoD) for Roadmap Tasks:**
   Tracked roadmap tasks MUST NOT be declared complete until ALL checks pass:
   - [ ] Automated git check passes: `git diff --check` exits with code 0.
   - [ ] Markdown relative links and branch targets validated.
   - [ ] Conventional Commits in English (`feat(hub): ...`, `docs(task): ...`).
   - [ ] Active task logged in `.agent/TASK.md` completed log and next task promoted.

---

## Fail-Stop Protocol & Escalation Hierarchy

If an automated command or build step fails **2 consecutive times** with the same root cause:
1. The agent MUST STOP execution immediately.
2. The agent MUST NOT attempt unapproved workarounds.
3. The agent MUST escalate to the user with a structured diagnostic block:
   ```yaml
   failure_stage: "command or step name"
   error_signature: "exact error string"
   consecutive_failures: 2
   root_cause_analysis: "technical description"
   attempted_fixes:
     - "attempt 1 summary"
     - "attempt 2 summary"
   pending_decision: "question or proposed options for the user"
   ```

---

## Task Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Subtasks: `[XX.Y.Z]`. Exactly **one** task active in `RUNNING` status. IDs are immutable within a release cycle. After Git tag: archive to `ARCHIVE.md`, restart at `[00.1]`/`[01.1]`, and update the active task ID.

**Next ID:** Derived solely from Active Task + Log of current cycle. Ignore Future Backlog and closing sections. Same epic → `Y+1` (`[04.4]` → `[04.5]`). New epic → `[XX+1.1]`. Never jump to `90.x`/`99.x` unless performing refactoring/release explicitly requested by the user.

**Release:** `[99.1]` is not a queue item. It becomes active only with explicit human instruction. Never trigger release tags autonomously; never treat `99.x` as an artificial ceiling.

| Prefix | Phase | Hub Scope |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Discovery | Setup, linters, initial audit |
| **`01.x`** | Foundation & Guardrails | Critical fixes, CI, canonical contracts |
| **`02.x`–`89.x`** | Epics | New templates, hub features (each decade = one epic) |
| **`90.x`** | Refactoring | Technical debt without contract modifications |
| **`99.x`** | Hardening & Release | Final audit and release tagging — human approval required |

---

## Post-Release Hygiene (Trigger: Git tag on any phase)

Not restricted to phase `99.x`. When releasing `vX.Y.Z`:

1. **Archive:** Move completed log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Promote definitive architectural decisions to ADRs; prune ephemeral scratch notes in `NOTES.md`.
3. **Perimeter:** Sync `.env.example` and `README.md` to the release tag.
4. **Reset:** Reset task numbering; correct active task ID; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

---

## 🔄 Inter-Branch Synchronization Protocol

Because branches `greenfield`, `brownfield`, `blackbox`, `infra`, and `main` have intentionally distinct root directories, **`git merge` between them is strictly prohibited**. Merging pollutes clean template roots.

To propagate governance or shared tooling improvements across branches:

### 1. Atomic Commit Cherry-Picking
When creating generic improvements applicable across templates:
```bash
# On target branch (e.g., greenfield, brownfield, blackbox, infra):
git cherry-pick <commit-hash>
```

### 2. Selective File Checkout
To sync shared canonical files (e.g., `.gitignore`, `.env.example`):
```bash
# On target branch:
git checkout <source-branch> -- path/to/file
git commit -m "chore(sync): sync <file> from <source-branch>"
```

### 3. Responsibility Matrix
- `.github/workflows/ci.yml`: Centrally maintained and versioned on `main`.
- `.gitignore` and `.env.example`: Kept synchronized across all branches.
- `.agent/TASK.md` and `.agent/NOTES.md`:
  - On `main`: Tracks ecosystem and Template Hub tasks/decisions.
  - On `greenfield`, `brownfield`, `blackbox`, `infra`: Kept as clean canonical templates for end users.

---

## 📦 Git & Commit Standards (Conventional Commits & Atomicity)

### 1. Atomic Commits
1. **Single Responsibility:** Each commit MUST represent a single, cohesive, verifiable change. NEVER combine governance, documentation, and script updates into one commit.
2. **Step-by-Step Cycle:** Commit and validate atomically before moving to the next phase.
3. **Surgical Diffs:** Avoid unintended files, accidental whitespace changes, or temporary files.

### 2. Conventional Commits Syntax
All commit messages MUST follow `<type>(<scope>): <imperative summary>` in English:

| Type | Purpose | Hub Scope Example |
| :---: | :--- | :--- |
| **`feat`** | New capability or starter branch | `feat(hub): add infra template branch to matrix` |
| **`fix`** | Bug fix in scripts or workflows | `fix(installer): resolve remote execution flag parsing` |
| **`docs`** | Documentation or task log updates | `docs(task): log task 07.1 completion` |
| **`refactor`** | Code/structure cleanup without behavior change | `refactor(ci): streamline multi-branch matrix testing` |
| **`test`** | Automated tests or contract assertions | `test(infra): add scaffolding verification step` |
| **`chore`** | Maintenance, inter-branch sync, or configs | `chore(sync): sync .gitignore from greenfield` |

### 3. Contrast Pairs

```markdown
# BAD: Combining multiple concerns, vague or past-tense message
git commit -m "fixed stuff, updated docs and updated init.sh"

# GOOD: Single atomic change with RFC-compliant imperative verb
git commit -m "fix(installer): resolve remote execution flag parsing"
```

---

## Golden Rules of this Hub

- **MUST NOT** run `git merge` between specialized branches (`main`, `greenfield`, `brownfield`, `blackbox`, `infra`). Propagate changes exclusively via `git cherry-pick` or selective file checkout.
- **MUST NOT** mix specific template files into `main`. Each starter MUST remain strictly isolated at the root of its own branch.
- **MUST NOT** force-push (`git push --force`) to primary branches without explicit user permission.
- **MUST NOT** break backward compatibility of `install.sh` and `init.sh`.
- **MUST** preserve lean context in `.agent/TASK.md` and `.agent/NOTES.md`.