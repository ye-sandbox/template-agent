# Agent Guidelines and Rules (Template Hub Repository)

You are the lead engineer responsible for governing, maintaining, and evolving this repository: **Agent-Driven Development (ADD) Template Hub**.

> 💡 **Repository Context:** This repository is NOT a business application. It is the **Central Template Hub** providing foundational templates for new projects and legacy adoption. The repository uses a **Specialized Branches as Templates** architecture. Cross-cutting playbooks (UI, QA, host infrastructure) are maintained separately in [`ye-sandbox/agent-skills`](https://github.com/ye-sandbox/agent-skills).

---

## 🌿 Repository Branch Map

- **`main` (This Branch):** Documentation hub, decision matrix, governance guidelines, and ecosystem evolution history.
- **`greenfield`:** Clean starter kit for projects built from scratch (`.agent/adr/`, `.agent/skills/`, etc. at root).
- **`brownfield`:** Injection template for existing/legacy codebases (`install.sh`, `.agent/INVARIANTS.md`, Task 00 Discovery).
- **`blackbox`:** Template for reverse engineering, scrapers, automations, and undocumented closed APIs (`.agent/ENDPOINTS.md`, `.agent/skills/reverse-engineering/`, `init.sh`).
- **`infra`:** Infrastructure-as-Code (IaC), Docker Compose, service orchestration, and Homelab (`.agent/SERVICES.md`, `.agent/skills/compose-service/`, `compose.yaml.example`, `init.sh`).

---

## Mandatory Execution Protocol

1. **Read Context First:** Before editing or creating files on `main`, inspect `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md`.
2. **Respect Branch Isolation:**
   - For greenfield/scratch project workflows: checkout and test on `greenfield`.
   - For legacy injection or brownfield guardrails: checkout and test on `brownfield`.
   - For reverse engineering, scrapers, or closed APIs: checkout and test on `blackbox`.
   - For infrastructure, Docker Compose, or service templates: checkout and test on `infra`.
   - For general hub docs, governance, or new template branches: work directly on `main`.
3. **Plan-First Workflow:**
   - Update `Status` in `.agent/TASK.md` to `PLANNING` (or `EM PLANEJAMENTO`).
   - Present a detailed action plan listing affected branches and files.
   - Wait for explicit user approval before executing changes or switching branches.
   - Upon approval, update `Status` to `RUNNING` (or `EM EXECUÇÃO`).
4. **Definition of Done (DoD):**
   - [ ] Clear, consistently formatted Markdown documentation.
   - [ ] Validated relative links between branches and files.
   - [ ] Semantic Conventional Commits in English (e.g. `feat(hub): ...`, `docs(greenfield): ...`, `fix(brownfield): ...`).
   - [ ] Task completed and logged in `.agent/TASK.md`.

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
4. **Reset:** Reset task numbering; correct active task ID; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md` (never as an active backlog checkbox).

---

## 🔄 Inter-Branch Synchronization Protocol

Because branches `greenfield`, `brownfield`, `blackbox`, `infra`, and `main` have intentionally distinct root directories, **`git merge` between them is strictly prohibited**. Merging pollutes clean template roots.

To propagate governance or shared tooling improvements across branches:

### 1. Atomic Commit Cherry-Picking
When creating generic improvements applicable across templates (formatting rules, linter tweaks, doc patterns):
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
1. **Single Responsibility:** Each commit must represent a single, cohesive, verifiable change. Never combine governance, documentation, and script updates into one commit.
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

### 3. Recommended Scopes
- `hub`: Global documentation, hub README, or repository decision matrix.
- `greenfield`: Greenfield starter template files.
- `brownfield`: Brownfield legacy template files (`install.sh`, etc.).
- `blackbox`: Blackbox reverse-engineering template files.
- `infra`: Infrastructure and Docker Compose template files.
- `ci`: Automation and CI pipeline (`.github/workflows/ci.yml`).
- `task`: Updates to `.agent/TASK.md`.

---

## Golden Rules of this Hub

- **NEVER** run `git merge` between specialized branches (`main`, `greenfield`, `brownfield`, `blackbox`, `infra`). Propagate changes exclusively via `git cherry-pick` or selective file checkout.
- **NEVER** mix specific template files into `main`. Each starter must remain strictly isolated at the root of its own branch.
- **NEVER** force-push (`git push --force`) to primary branches without explicit user permission.
- **NEVER** break backward compatibility of `install.sh` and `init.sh`.
- **PRESERVE LEAN CONTEXT:** Keep `.agent/TASK.md` and `.agent/NOTES.md` concise, structured, and noise-free.