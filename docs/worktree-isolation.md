---
author_type: agent-assisted
author: Architecture Team
reviewed_by: Human Lead
date: 2026-11-06
status: accepted
type: architectural-specification
---

# Isolated Worktree & Sandbox Runner Integration Specification

Canonical specification and operational recipes for Git worktree isolation, automated dependency bootstrapping, sandbox execution, and deterministic lifecycle management within the Agent-Driven Development (ADD) Template Hub.

---

## 1. Overview & Core Philosophy

Parallel multi-agent execution (`[PARALLEL: Wx]`) and autonomous worker subagents require hermetic workspace isolation to guarantee:
1. **Zero State Pollution:** Worker agents must never mutate files concurrently in the primary working tree or leave uncommitted debris on `main`.
2. **Deterministic Verification:** Test suites (`Verify:`) must execute in an isolated environment reflecting the exact state of the task's atomic changes.
3. **Execution Velocity:** Provisioning an isolated environment must complete in milliseconds without downloading gigabytes of duplicate dependencies.

This specification defines the **Lifecycle Protocol**, the **Dependency Bootstrapping Strategy (Fast-Link vs. Isolated-Install)**, and **Operational Recipes** for orchestrators and task runners (e.g. `task-queue` and `run-wave.sh`).

---

## 2. Worktree Lifecycle Protocol

The worktree lifecycle consists of 6 sequential phases managed by the `Lead / Orchestrator` (or automated wave runner):

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. Provisioning     │ git worktree add -b task-<id> <path> HEAD        │
├─────────────────────┼───────────────────────────────────────────────────┤
│ 2. Bootstrapping    │ Clone .env + Fast-Link or Isolated-Install        │
├─────────────────────┼───────────────────────────────────────────────────┤
│ 3. Sandboxing       │ Restrict Worker to <path> and Whitelisted Paths:  │
├─────────────────────┼───────────────────────────────────────────────────┤
│ 4. Verification     │ Reviewer executes Verify: command in <path>       │
├─────────────────────┼───────────────────────────────────────────────────┤
│ 5. Integration      │ Lead fast-forwards/cherry-picks atomic commit     │
├─────────────────────┼───────────────────────────────────────────────────┤
│ 6. Teardown         │ git worktree remove --force + git worktree prune  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Phase 1: Provisioning & Path Resolution

Worktrees may be provisioned in either of two standard locations:
- **System Ephemeral Path (Default for CI / Sandbox Runners):**
  ```bash
  WORKTREE_BASE="${TMPDIR:-/tmp}/worktrees"
  WORKTREE_PATH="${WORKTREE_BASE}/task-${TASK_ID}"
  ```
- **Local In-Repository Path (Convenient for local developer inspection):**
  ```bash
  WORKTREE_PATH=".worktrees/task-${TASK_ID}"
  ```
  *(Note: `.worktrees/` MUST be listed in `.gitignore` across all branches).*

**Provisioning Command:**
```bash
mkdir -p "$(dirname "${WORKTREE_PATH}")"
git worktree add -b "task-${TASK_ID}" "${WORKTREE_PATH}" HEAD
```

---

## 3. Dependency Bootstrapping: Fast-Link vs. Isolated-Install

A bare `git worktree` contains only Git-tracked files. It completely lacks uncommitted files and ignored artifacts (`.env`, `node_modules/`, `.venv/`, caches). Running `npm install` or `pip install` from scratch in every parallel worktree causes severe I/O bottlenecks and cache lock contention.

Because every subagent task is defined by a machine-parseable micro-contract containing `Paths:`, the runner inspects `Paths:` to select the optimal bootstrapping mode:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Micro-Contract (Paths:)                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
            ┌───────────────────────┴───────────────────────┐
            ▼                                               ▼
[Paths: does NOT touch manifests]                [Paths: TOUCHES manifests]
(e.g., src/**, docs/**, tests/**)                 (e.g., package.json, pyproject.toml)
            │                                               │
            ▼                                               ▼
 Mode 1: Fast-Link (Zero-Copy)                   Mode 2: Isolated-Install
 • Symlinks existing dependencies               • Clean install in worktree
 • Duration: < 50ms                             • Uses global package manager cache
 • 0 MB additional disk consumption             • Prevents polluting root workspace
```

### Mode 1: Fast-Link (Zero-Copy Strategy)
Used for >90% of development tasks where dependencies are unchanged:
- **Node.js:** Symlink `${ROOT_DIR}/node_modules` $\rightarrow$ `${WORKTREE_PATH}/node_modules`
- **Python:** Symlink `${ROOT_DIR}/.venv` $\rightarrow$ `${WORKTREE_PATH}/.venv` (or export `VIRTUAL_ENV`)
- **Go / Rust:** Retain default shared `GOPATH` / `CARGO_HOME` caches.

### Mode 2: Isolated-Install Strategy
Used when `Paths:` explicitly includes dependency manifest files:
- **Node.js (`package.json`, `pnpm-lock.yaml`, `package-lock.json`):**
  Execute `pnpm install` / `npm ci` inside `${WORKTREE_PATH}` utilizing the local offline cache.
- **Python (`pyproject.toml`, `requirements.txt`, `Pipfile`):**
  Create an isolated virtual environment (`python -m venv "${WORKTREE_PATH}/.venv"`) or use `uv venv` with global hardlinks.

### Environment & Secrets Propagation (`.env`)
Untracked local configurations and secrets necessary for test suites:
- If `${ROOT_DIR}/.env` exists, **copy** (do NOT symlink) to `${WORKTREE_PATH}/.env`.
- Copying ensures workers can safely inject mock credentials or temporary test variables without mutating the root developer environment.

### Sandboxing & Process Confinement
Worker execution within `${WORKTREE_PATH}` is bound to hermetic execution sandboxes (Bubblewrap `bwrap` or rootless OCI containers) to enforce read-only system mounts, ephemeral `tmpfs /tmp`, and network air-gapping.
Detailed specification and execution wrappers: [`docs/agent-sandbox.md`](agent-sandbox.md).

---

## 4. Canonical Bootstrap Implementation

The reference bash implementation below is incorporated into runner scripts (`run-wave.sh` or local automation):

```bash
#!/usr/bin/env bash
# ==============================================================================
# Helper: bootstrap_worktree_dependencies
# Usage: bootstrap_worktree_dependencies <root_dir> <worktree_dir> <manifest_changed_bool>
# ==============================================================================
bootstrap_worktree_dependencies() {
  local ROOT_DIR="$1"
  local WORKTREE_DIR="$2"
  local TOUCHES_DEPS="${3:-false}"

  # 1. Environment propagation
  if [ -f "${ROOT_DIR}/.env" ] && [ ! -f "${WORKTREE_DIR}/.env" ]; then
    cp "${ROOT_DIR}/.env" "${WORKTREE_DIR}/.env"
  elif [ -f "${ROOT_DIR}/.env.example" ] && [ ! -f "${WORKTREE_DIR}/.env" ]; then
    cp "${ROOT_DIR}/.env.example" "${WORKTREE_DIR}/.env"
  fi

  # 2. Node.js ecosystem
  if [ -f "${ROOT_DIR}/package.json" ]; then
    if [ "$TOUCHES_DEPS" = "false" ] && [ -d "${ROOT_DIR}/node_modules" ]; then
      ln -s "${ROOT_DIR}/node_modules" "${WORKTREE_DIR}/node_modules"
    else
      (
        cd "${WORKTREE_DIR}"
        if [ -f "pnpm-lock.yaml" ]; then
          pnpm install --frozen-lockfile --prefer-offline 2>/dev/null || pnpm install
        elif [ -f "package-lock.json" ]; then
          npm ci --prefer-offline 2>/dev/null || npm install
        else
          npm install
        fi
      )
    fi
  fi

  # 3. Python ecosystem
  if [ -f "${ROOT_DIR}/pyproject.toml" ] || [ -f "${ROOT_DIR}/requirements.txt" ]; then
    if [ "$TOUCHES_DEPS" = "false" ] && [ -d "${ROOT_DIR}/.venv" ]; then
      ln -s "${ROOT_DIR}/.venv" "${WORKTREE_DIR}/.venv"
    else
      (
        cd "${WORKTREE_DIR}"
        if command -v uv >/dev/null 2>&1; then
          uv venv .venv && source .venv/bin/activate && uv pip install -r requirements.txt 2>/dev/null || true
        else
          python3 -m venv .venv && source .venv/bin/activate && pip install -q -r requirements.txt 2>/dev/null || true
        fi
      )
    fi
  fi
}
```

---

## 5. Verification, Integration & Teardown

### Step 4: Verification Gate
Before integrating changes into the primary branch:
1. Reviewer or Lead navigates to `${WORKTREE_PATH}`.
2. Reviewer executes the designated `Verify:` command (e.g. `npm test`, `./tests/smoke.sh`).
3. Reviewer executes `git diff --check` to ensure no trailing whitespace or unresolved merge markers.
4. Reviewer verifies that untracked files or symlinks are not accidentally committed.

### Step 5: Integration
If verification passes and an atomic commit was authored:
```bash
git checkout <target-branch>
git merge --ff-only "task-${TASK_ID}"
```
*(If fast-forward is not possible due to independent parallel commits on disjoint files, lead performs a non-conflicting cherry-pick or rebase).*

### Step 6: Teardown & Clean Garbage Collection
Worktrees MUST be pruned immediately after integration or upon cancellation:
```bash
# 1. Force remove worktree directory (safely removes symlinks without touching root)
git worktree remove --force "${WORKTREE_PATH}" 2>/dev/null || rm -rf "${WORKTREE_PATH}"

# 2. Delete temporary task branch
git branch -D "task-${TASK_ID}" 2>/dev/null || true

# 3. Prune internal Git worktree administrative records
git worktree prune
```

---

## 6. Circuit Breaker & Fail-Safe Cleanup

In the event of consecutive failures (3 for general starters, 2 for sensitive starters) or sudden subagent crashes:
1. **Dangling Worktree Locks:** Traps (`trap 'cleanup' EXIT INT TERM`) must be declared in runner scripts so that incomplete worktrees and locked index files (`.git/worktrees/<name>/locked`) are cleared.
2. **Escalation Payload:** The orchestrator halts execution, records the failure diagnosis, and prunes the failed worktree:
   ```yaml
   failure_stage: "worktree_verification"
   task_id: "[XX.Y]"
   worktree_path: "/tmp/worktrees/task-xx-y"
   consecutive_failures: 3
   root_cause_analysis: "Verify command failed with code 1 in isolated worktree"
   pending_decision: "Inspect failure logs and provide approved fix"
   ```
